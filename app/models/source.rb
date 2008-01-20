# == Schema Information
# Schema version: 3
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
    for hcal in SourceParser.to_hcals(format_type, opts)
      events << Event.from_hcal(hcal)
    end
    return events
  end
end
