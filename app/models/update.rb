# == Schema Information
# Schema version: 20110604174521
#
# Table name: updates
#
#  id         :integer         not null, primary key
#  source_id  :integer
#  status     :text
#  created_at :datetime
#  updated_at :datetime
#

class Update < ActiveRecord::Base
  belongs_to :source
end
