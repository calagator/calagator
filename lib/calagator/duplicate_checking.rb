# frozen_string_literal: true

# = DuplicateChecking
#
# This mixin provides a way for ActiveRecord classes to find and squash duplicates.
#
# Example:
#
#   # Define your class
#   class Thing < ApplicationRecord
#     # Load the mixin into your class
#     include DuplicateChecking
#
#     # Declare attributes that should be ignored during duplicate checks
#     duplicate_checking_ignores_attributes :random_value
#
#     # Declare associations that should be ignored during duplicate squashing
#     duplicate_squashing_ignores_associations :tags
#
#     # Declare an optional scope to be applied in find_duplicates_by_type
#     duplicate_finding_scope -> { active }
#   end
#
#   # Set duplicates on objects
#   foo1 = Thing.create!!:name => "foo")
#   foo2 = Thing.create!(:name => "foo", :duplicate_of => foo1)
#   bar  = Thing.create!(:name => "bar")
#
#   # Check whether record is set as duplicate
#   foo1.duplicate? # => false
#   foo2.duplicate? # => true
#   bar.duplicate?  # => false
#
#   # Find duplicate of a record
#   foo3.find_exact_duplicates # => [foo1, foo2]
#   bar.find_exact_duplicates  # => nil
require 'calagator/duplicate_checking/duplicate_finder'
require 'calagator/duplicate_checking/duplicate_squasher'

module Calagator
  module DuplicateChecking
    DUPLICATE_MARK_COLUMN = :duplicate_of_id
    DEFAULT_SQUASH_METHOD = :mark
    DUPLICATE_CHECKING_IGNORES_ATTRIBUTES =
      Set.new((%w[created_at updated_at id] + [DUPLICATE_MARK_COLUMN]).map(&:to_sym))

    def self.included(base)
      base.extend ClassMethods
    end

    def duplicate?
      duplicate_of.present?
    end
    alias marked_as_duplicate? duplicate?

    def primary?
      !duplicate?
    end

    # Return the ultimate primary for a record, which may be the record itself.
    def originator
      parent = self
      seen = Set.new

      loop do
        return parent if parent.primary?
        if seen.include?(parent)
          raise DuplicateCheckingError, "Loop detected in duplicates chain at #{parent.class}##{parent.id}"
        end

        seen << parent
        parent = parent.duplicate_of
      end
    end

    # Return either an Array of exact duplicates for this record, or nil if no exact duplicates were found.
    #
    # Note that this method requires that all associations are set before this method is called.
    def find_exact_duplicates
      matchable_attributes = attributes.reject do |key, _value|
        self.class.duplicate_checking_ignores_attributes.include?(key.to_sym)
      end
      duplicates = self.class.where(matchable_attributes).reject { |t| t.id == id }
      duplicates.presence
    end

    module ClassMethods
      def self.extended(klass)
        klass.instance_eval do
          cattr_accessor(:_duplicate_checking_ignores_attributes) { Set.new }
          cattr_accessor(:_duplicate_squashing_ignores_associations) { Set.new }
          cattr_accessor(:_duplicate_finding_scope) { -> { all } }
          cattr_accessor(:_after_squashing_duplicates) { ->(primary) {} }

          belongs_to :duplicate_of, class_name: name, foreign_key: DUPLICATE_MARK_COLUMN
          has_many   :duplicates,   class_name: name, foreign_key: DUPLICATE_MARK_COLUMN

          scope :marked_duplicates, -> { where("#{table_name}.#{DUPLICATE_MARK_COLUMN} IS NOT NULL") }
          scope :non_duplicates, -> { where("#{table_name}.#{DUPLICATE_MARK_COLUMN} IS NULL") }
        end
      end

      # Return set of attributes that should be ignored for duplicate checking
      def duplicate_checking_ignores_attributes(*args)
        unless args.empty?
          _duplicate_checking_ignores_attributes.merge(args.map(&:to_sym))
        end
        DUPLICATE_CHECKING_IGNORES_ATTRIBUTES + _duplicate_checking_ignores_attributes
      end

      # Return set of associations that will be ignored during duplicate squashing
      def duplicate_squashing_ignores_associations(*args)
        unless args.empty?
          _duplicate_squashing_ignores_associations.merge(args.map(&:to_sym))
        end
        _duplicate_squashing_ignores_associations
      end

      def duplicate_finding_scope(*args)
        self._duplicate_finding_scope = args.first unless args.empty?
        _duplicate_finding_scope
      end

      def after_squashing_duplicates(*args)
        self._after_squashing_duplicates = args.first unless args.empty?
        _after_squashing_duplicates
      end

      # Return Hash of duplicate events grouped by the +type+.
      def find_duplicates_by_type(type)
        DuplicateFinder.new(self, type.split(',')).find do |scope|
          scope.instance_exec &duplicate_finding_scope
        end
      end

      # Squash duplicates. Options accept ActiveRecord instances or IDs.
      #
      # Options:
      # :duplicates => ActiveRecord instance(s) to mark as duplicates
      # :primary => ActiveRecord instance to use as the primary record
      def squash(primary, duplicates)
        DuplicateSquasher.new(primary, duplicates, name.downcase).squash.tap do |squasher|
          after_squashing_duplicates.call(primary) unless squasher.failure
        end
      end
    end
  end

  class DuplicateCheckingError < RuntimeError
  end
end
