# == Schema Information
# Schema version: 7
#
# Table name: venues
#
#  id             :integer         not null, primary key
#  title          :string(255)
#  description    :text
#  address        :string(255)
#  url            :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  street_address :string(255)
#  locality       :string(255)
#  region         :string(255)
#  postal_code    :string(255)
#  country        :string(255)
#  latitude       :float
#  longitude      :float
#  email          :string(255)
#  telephone      :string(255)
#

class Venue < ActiveRecord::Base
  include DuplicateChecking
  has_many :events, :dependent => :nullify
  belongs_to :source
  belongs_to :duplicate_of, :class_name => "Venue", :foreign_key => "duplicate_of_id"
  has_many :duplicates, :class_name => "Venue", :foreign_key => "duplicate_of_id"

  validates_presence_of :title

  # Return an Array of Venue instances that are not duplicates, in sorted order.
  def self.find_non_duplicates
    Venue.find(:all, :order => "title ASC", :conditions => "duplicate_of_id IS NULL")
  end

  # Return an Array of Venue instances that are duplicates, in sorted order.
  def self.find_duplicates
    Venue.find(:all, :order => "title ASC", :conditions => "duplicate_of_id IS NOT NULL")
  end

  # Returns a new Venue created from an AbstractLocation.
  def self.from_abstract_location(abstract_location)
    returning Venue.new do |venue|
      unless abstract_location.blank?
        abstract_location.each_pair do |key, value|
          venue[key] = value unless value.blank?
        end
      end
    end
  end

  # Squash duplicates. Options accept Venue instances or IDs.
  #
  # Options:
  # :duplicates => Venue(s) to mark as duplicates
  # :master => Venue to use as master
  def self.squash(opts)
    master     = opts[:master]
    duplicates = [opts[:duplicates]].flatten

    raise(ArgumentError, ":master not specified")     if master.blank?
    raise(ArgumentError, ":duplicates not specified") if duplicates.blank?

    case master
    when Venue # Expected class, do nothing
    when String, Fixnum then master = Venue.find(master.to_i)
    else raise TypeError, "Unknown :master type: #{master.class}"
    end

    for duplicate in duplicates
      case duplicate
      when Venue # Expected class, do nothing
      when String, Fixnum then duplicate = Venue.find(duplicate.to_i)
      else raise TypeError, "Unknown :duplicate type: #{duplicate.class}"
      end

      # Transfer any venues that use this now duplicate venue as a master
      unless duplicate.duplicates.blank?
        RAILS_DEFAULT_LOGGER.debug("Venue#squash: recursively squashing children of Venue@#{duplicate.id}")
        squash(:master => master, :duplicates => duplicate.duplicates)
      end

      # Transfer any events assigned to this duplicate venue to the master
      for event in duplicate.events
        RAILS_DEFAULT_LOGGER.debug("Venue#squash: transfering Event@#{event.id} from Venue@#{duplicate.id} to Venue@{master.id}")
        event.venue = master
        event.update_attribute(:venue, master) unless event.new_record?
      end

      # Mark this as a duplicate
      duplicate.duplicate_of = master
      duplicate.update_attribute(:duplicate_of, master) unless duplicate.new_record?
      RAILS_DEFAULT_LOGGER.debug("Venue#squash: marking Venue@#{duplicate.id} as duplicate of Venue@{master.id}")
    end
  end

  # Does this venue have any address information?
  def has_full_address?
    !"#{street_address}#{locality}#{region}#{postal_code}#{country}".blank?
  end

  # Display a single line address.
  def full_address()
    if has_full_address?
      "#{street_address}, #{locality} #{region} #{postal_code} #{country}"
    else
      nil
    end
  end

end
