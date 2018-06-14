class TimestampPrecision < ActiveRecord::Migration
  def change
  	add_column :stix_sightings, :sighted_at_precision, :string
  	add_column :stix_packages, :produced_time_precision, :string
  end
end
