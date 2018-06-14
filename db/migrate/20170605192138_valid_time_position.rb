class ValidTimePosition < ActiveRecord::Migration
  def change
  	add_column :stix_indicators, :start_time, :datetime
  	add_column :stix_indicators, :start_time_precision, :string
  	add_column :stix_indicators, :end_time, :datetime
  	add_column :stix_indicators, :end_time_precision, :string
  end
end
