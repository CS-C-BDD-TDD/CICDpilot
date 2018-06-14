class AddColumnsToWeatherMapData < ActiveRecord::Migration
  def change
    add_column :weather_map_data, :replicated_at, :date
    add_column :weather_map_data, :replicated, :boolean
    add_index :weather_map_data, :ip_address_raw
  end
end
