require 'lib/search_engine/base'

class SearchEngine::ActsAsSolr < SearchEngine::Base
  score true

  def self.add_searching_to(model)
    case model.new
    when Venue, Source
      # Do nothing
    when Event
      model.class_eval do
        # Names of columns and methods to create Solr indexes for
        def self.solr_indexable_fields
          return %w[
            url
            duplicate_for_solr
            start_time_for_solr
            end_time_for_solr
            event_title_for_solr
            venue_title_for_solr
            description_for_solr
            tag_list_for_solr
            text_for_solr
          ].map(&:to_sym)
        end

        unless RAILS_ENV == 'test'
          acts_as_solr :fields => self.solr_indexable_fields
        end

        # Number of records to index at once.
        def self.solr_rebuild_batch_size
          return 100
        end

        # Index only specific events with Solr.
        def self.rebuild_solr_index(batch_size=self.solr_rebuild_batch_size)
          timer = Time.now
          super(batch_size){|klass, opts| self.masters.find(:all, opts)}
          elapsed = Time.now - timer
          logger.debug(self.count>0 ? "Index for #{self.name} rebuilt in #{elapsed}s" : "Nothing to index for #{self.name}")
          return elapsed
        end

        # How similar should terms be to qualify as a match? This value should be
        # close to zero because Lucene's implementation of fuzzy matching is
        # defective, e.g., at 0.5 it can't even realize that "meetin" is similar to
        # "meeting".
        def self.solr_similarity
          return 0.3
        end

        # How much to boost the score of a match in the title?
        def self.solr_title_boost
          return 4
        end

        # Number of search matches to return by default.
        def self.solr_search_matches
          return 50
        end

        # Default search sort order
        def self.solr_default_search_order
          return :score
        end

        # Return an Array of non-duplicate Event instances matching the search +query+..
        #
        # Options:
        # * :order => How to order the entries? Defaults to :score. Permitted values:
        #   * :score => Sort with most relevant matches first
        #   * :date => Sort by date
        #   * :name => Sort by event title
        #   * :title => same as :name
        #   * :venue => Sort by venue title
        # * :limit => Maximum number of entries to return. Defaults to +solr_search_matches+.
        # * :skip_old => Return old entries? Defaults to false.
        def self.search(query, opts={})
          skip_old = opts[:skip_old] == true
          limit = opts[:limit] || self.solr_search_matches
          order = opts[:order].try(:to_sym) || self.solr_default_search_order

          title_boost = self.solr_title_boost
          similarity = self.solr_similarity

          formatted_query = \
            'NOT duplicate_for_solr:"1" AND (' \
            << query.downcase.gsub(/:/, '?').scan(/\S+/).map(&:escape_lucene).map{|term|
                <<-HERE
                  event_title_for_solr:#{term}^#{title_boost}
                    OR event_title_for_solr:#{term}~#{similarity}^#{title_boost}
                  OR tag_list_for_solr:#{term}^#{title_boost}
                    OR tag_list_for_solr:#{term}~#{similarity}^#{title_boost}
                  OR title:#{term}^#{title_boost}
                    OR title:#{term}~#{similarity}^#{title_boost}
                  OR #{term}~#{similarity}
                    OR #{term}
                HERE
              }.map(&:strip).join(' ').gsub(/\s{2,}/m, ' ') << ')'

          if skip_old
            formatted_query << " AND (start_time_for_solr:[#{Date.yesterday.to_time.strftime(self.solr_time_format)} TO #{self.solr_time_maximum}])"
          end

          logger.info("SearchEngine::ActsAsSolr::Event::search, formatted_query: #{formatted_query}")

          solr_opts = {
            :order => "score desc",
            :limit => limit,
            :scores => true,
          }
          events_by_score = self.find_with_solr(formatted_query, solr_opts)
          events = \
            case order
            when :score        then events_by_score
            when :name, :title then events_by_score.sort_by(&:event_title_for_solr)
            when :venue        then events_by_score.sort_by(&:venue_title_for_solr)
            when :date         then events_by_score.sort_by(&:start_time_for_solr)
            else raise ArgumentError, "Unknown order: #{order}"
            end
          return events
        end

        # Return an array of events found via Solr for the +formatted_query+ string
        # and +solr_opts+ hash. The primary benefit of this method is that it makes
        # it very easy to stub in specs.
        def self.find_with_solr(formatted_query, solr_opts={})
          return self.find_by_solr(formatted_query, solr_opts).results
        end

        #---[ Helpers ]---------------------------------------------------------

        # Format to use for storing Solr dates. Must generate a number that can be meaningfully sorted by value.
        def self.solr_time_format
          return '%Y%m%d%H%M'
        end

        # Maximum length of a #solr_time_format string.
        def self.solr_time_length
          return Time.now.strftime(self.class.solr_time_format).length
        end

        # Maximum numeric date for a Solr date string.
        def self.solr_time_maximum
          return ('9' * self.class.solr_time_length).to_i
        end

        # Return a purely numeric representation of the start_time
        def start_time_for_solr
          self.start_time ?
            self.start_time.utc.strftime(self.class.solr_time_format).to_i :
            ''
        end

        # Return a purely numeric representation of the end_time
        def end_time_for_solr
          self.end_time ?
            self.end_time.utc.strftime(self.class.solr_time_format).to_i :
            ''
        end

        # Returns value for whether the record is a duplicate or not
        def duplicate_for_solr
          self.duplicate_of_id.blank? ? 0 : 1
        end

        def event_title_for_solr
          self.class.sanitize_for_solr(self.title)
        end

        def venue_title_for_solr
          self.class.sanitize_for_solr(self.venue.try(:title))
        end

        def tag_list_for_solr
          self.class.sanitize_for_solr(self.tag_list)
        end

        def description_for_solr
          self.class.sanitize_for_solr(self.description)
        end

        # Return a string containing the text of all the indexable fields joined together.
        def text_for_solr
          # NOTE: The #text_for_solr method is one of the #solr_indexable_fields, so don't indexing it to avoid an infinite loop. Some fields are methods, not database columns, so use #send rather than read_attribute.
          (self.class.solr_indexable_fields - [:text_for_solr]).map{|name| self.class.sanitize_for_solr(self.send(name))}.join("|").to_s
        end

        def self.sanitize_for_solr(text)
          return text.to_s.downcase.gsub(/[^[:alnum:]]/, ' ').gsub(/\s{2,}/, ' ')
        end
      end
    else
      raise TypeError, "Unknown model class: #{model.name}"
    end
  end
end
