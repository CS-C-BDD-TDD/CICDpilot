class AddIndicatorWeatherMapColumns < ActiveRecord::Migration
  def change
    add_column :weather_map_data,:indicator_stix_id, :string
  end
end
