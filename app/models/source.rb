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
  def parse
    # TODO like parse this source and stuff
  end
end
