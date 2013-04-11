class AddRsvpUrl < ActiveRecord::Migration
  def up
  	add_column :events, :rsvp_url, :string
  end

  def down
  end
end
