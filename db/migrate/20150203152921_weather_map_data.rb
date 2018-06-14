class WeatherMapData < ActiveRecord::Migration
  def up
    create_table :weather_map_data do |t|
      t.string :ip_address_raw
      t.string :ipv4_address_normalized
      t.string :ipv6_address_normalized
      t.string :ipv4_address_cybox_hash
      t.string :ipv6_address_cybox_hash
      t.decimal :ipv4_start, :precision => 10, :scale => 0
      t.decimal :ipv4_end, :precision => 10, :scale => 0
      t.integer :ipv4_prefix
      t.string :iso_country_code
      t.string :com_threat_score
      t.string :gov_threat_score
      t.string :agencies_sensors_seen_on, limit: 1000
      t.string :first_date_seen_raw
      t.datetime :first_date_seen
      t.string :last_date_seen_raw
      t.datetime :last_date_seen
      t.datetime :deleted_at
      t.timestamps
    end
  end

  def down
    drop_table :weather_map_data
  end
end
