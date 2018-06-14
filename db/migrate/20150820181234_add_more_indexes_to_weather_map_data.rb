class AddMoreIndexesToWeatherMapData < ActiveRecord::Migration
  def change
    add_index :weather_map_data, :ipv4_address_normalized, unique: true
    add_index :cybox_addresses, :address_value_normalized
  end
end
