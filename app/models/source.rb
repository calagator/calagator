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

require 'mofo'
require 'open-uri'

class Source < ActiveRecord::Base
  # Returns an Array of Event objects that were imported into this queue.
  def parse(opts={})
    send "parse_#{format_type.downcase}", opts
  end

  # Returns content for a URL. Easier to stub.
  def read_url(url)
    open(url){|h| h.read}
  end

  def parse_hcal(opts)
    returning([]) do |events|
      for result in [hCalendar.find(:text => read_url(url))].flatten
        events << Event.new(:title => result.summary, :description => result.description, :start_time => result.dtstart, :url => result.url)
      end
    end
  end
end
