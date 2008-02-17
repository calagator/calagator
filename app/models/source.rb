# == Schema Information
# Schema version: 4
#
# Table name: sources
#
#  id          :integer         not null, primary key
#  title       :string(255)     
#  url         :string(255)     
#  format_type :string(255)     
#  imported_at :datetime        
#  created_at  :datetime        
#  updated_at  :datetime        
#

# == Source
#
# A model that represents a source of events data, such as feeds for hCal, iCal, etc.
class Source < ActiveRecord::Base
  # Returns an Array of Event objects that were read from this source.
  def to_events(opts={})
    opts[:url] ||= url
    events = []
    SourceParser.to_abstract_events(format_type, opts).each do |e|
      events << Event.from_abstract_event(e)
    end
    return events
  end
end
