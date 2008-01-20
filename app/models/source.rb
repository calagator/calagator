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

class Source < ActiveRecord::Base
  # Returns an Array of Event objects that were imported into this queue.
  def parse(opts={})
    opts[:source] = self
    SourceParser.parse(format_type, opts)
  end
end
