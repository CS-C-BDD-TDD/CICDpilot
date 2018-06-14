class StagingWeatherMapData < ActiveRecord::Migration
  def change
    create_table :staging_weather_map_data, id: false do |t|
      t.string :ip_address
      t.string :iso_country_code
      t.string :com_threat_score
      t.string :gov_threat_score
      t.string :combined_score
      t.string :agencies_sensors_seen_on, limit: 1000
      t.string :first_date_seen
      t.string :last_date_seen
      t.string :category_list, limit: 1000
    end
  end
end
