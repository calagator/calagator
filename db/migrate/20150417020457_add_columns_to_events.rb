class AddColumnsToEvents < ActiveRecord::Migration
  def change
    add_column    :events, :contact_information, :string
    add_column    :events, :signup_instructions, :string
    add_column    :events, :minimum_age,         :integer
  end
end
