module Calagator
  class Event < ActiveRecord::Base
    class Browse < Struct.new(:params, :start_date, :end_date)
      def events
        query = Event.non_duplicates.ordered_by_ui_field(params[:order]).includes(:venue, :tags)
        if params[:date]
          query.within_dates(start_date, end_date)
        else
          query.future
        end
      end
    end
  end
end
