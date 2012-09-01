class SpecifyVenuesLatitudeAndLongitudePrecision < ActiveRecord::Migration
  FIELDS = %w[latitude longitude].map(&:to_sym)

  def up
    for field in FIELDS
      change_column :venues, field, :decimal, :precision => 7, :scale => 4
    end
  end

  def down
    for field in FIELDS
      change_column :venues, field, :decimal
    end
  end
end
