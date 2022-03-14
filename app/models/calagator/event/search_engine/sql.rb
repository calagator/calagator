# frozen_string_literal: true

module Calagator
  class Event < Calagator::ApplicationRecord
    class SearchEngine
      class Sql < Struct.new(:query, :opts)
        # Return an Array of non-duplicate Event instances matching the search +query+..
        #
        # Options:
        # * :order => How to order the entries? Defaults to :date. Permitted values:
        #   * :date => Sort by date
        #   * :name => Sort by event title
        #   * :title => same as :name
        #   * :venue => Sort by venue title
        # * :limit => Maximum number of entries to return. Defaults to 50.
        # * :skip_old => Return old entries? Defaults to false.
        def self.search(*args)
          new(*args).all
        end

        def self.score?
          false
        end

        def all
          current_events + past_events
        end

        private

        def current_events
          search.current.scope.to_a
        end

        def past_events
          skip_old ? [] : search.past.scope.to_a
        end

        def search
          base.keywords.order.limit
        end

        def skip_old
          opts[:skip_old] == true
        end

        protected

        attr_accessor :scope

        def base
          column_names = Event.column_names.map { |name| "events.#{name}" }
          column_names << 'venues.id'
          @scope = Event.all
                        .group(column_names)
                        .joins("LEFT OUTER JOIN taggings on taggings.taggable_id = events.id AND taggings.taggable_type LIKE '%Event'")
                        .joins('LEFT OUTER JOIN tags ON tags.id = taggings.tag_id')
                        .includes(:venue)
                        .references(:venues, :tags)
          self
        end

        def keywords
          @scope = @scope.where('LOWER(events.title) LIKE ?', "%#{query.downcase}%")
                         .or(@scope.where('LOWER(events.description) LIKE ?', "%#{query.downcase}%"))
                         .or(@scope.where(['LOWER(events.url) LIKE ?', "%#{query.downcase}%"]))
                         .or(@scope.where(['LOWER(tags.name) = ?', query]))
          self
        end

        def order
          order = case opts[:order].try(:to_sym)
                  when :name, :title
                    'LOWER(events.title) ASC'
                  when :location, :venue
                    'LOWER(venues.title) ASC'
                  else
                    'events.start_time DESC'
          end
          @scope = @scope.order(Arel.sql(order))
          self
        end

        def limit
          limit = opts.fetch(:limit, 50)
          @scope = @scope.limit(limit)
          self
        end

        def current
          @scope = @scope.where('events.start_time >= ?', Date.yesterday.to_time)
          self
        end

        def past
          @scope = @scope.where('events.start_time < ?', Date.yesterday.to_time)
          self
        end
      end
    end
  end
end
