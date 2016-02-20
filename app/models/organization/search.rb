class Organization < ActiveRecord::Base
  class Search < Struct.new(:tag, :query, :all)
    def initialize attributes = {}
      members.each do |key|
        send "#{key}=", attributes[key]
      end
    end

    def organizations
      @organizations ||= if query
        Organization.search(query)
      else
        base.search.scope
      end
    end

    def most_active_organizations
      base.scope.order('events_count DESC').limit(10)
    end

    def newest_organizations
      base.scope.order('created_at DESC').limit(10)
    end

    def results?
      query || tag || all
    end

    protected

    def base
      @scope = Organization.order(:title).non_duplicates
      self
    end

    def search
      @scope = @scope.tagged_with(tag) if tag.present? # searching by tag
      self
    end

    def scope
      @scope
    end
  end
end

