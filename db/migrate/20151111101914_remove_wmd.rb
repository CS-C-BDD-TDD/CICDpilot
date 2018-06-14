class RemoveWmd < ActiveRecord::Migration
  class MIndicator < ActiveRecord::Base;self.table_name = :stix_indicators; end
  class MWeatherMapData < ActiveRecord::Base;self.table_name = :weather_map_data; end
  class MAddress < ActiveRecord::Base;self.table_name = :cybox_addresses; end

  def up
    puts "Adding columns to Address Table"
    change_table :cybox_addresses do |t|
      t.column :iso_country_code, :string
      t.column :com_threat_score, :string
      t.column :gov_threat_score, :string
      t.column :agencies_sensors_seen_on, :string, limit: 1000
      t.column :first_date_seen_raw, :string
      t.column :first_date_seen, :datetime
      t.column :last_date_seen_raw, :string
      t.column :last_date_seen, :datetime
      t.column :combined_score, :string
      t.column :category_list, :string, :limit => 500
    end

    puts "Transitioning WMD to Addresses"
    MWeatherMapData.find_in_batches.with_index do |group, batch|
      puts "Processing WMD group #{batch}"
      group.each do |wmd|
        address = MAddress.find_by(address_value_normalized: wmd.ipv4_address_normalized)
        address.update_attributes(
            iso_country_code: wmd.iso_country_code,
            com_threat_score: wmd.com_threat_score,
            gov_threat_score: wmd.gov_threat_score,
            combined_score: wmd.combined_score,
            category_list: wmd.category_list,
            agencies_sensors_seen_on: wmd.agencies_sensors_seen_on,
            first_date_seen_raw: wmd.first_date_seen_raw,
            first_date_seen: wmd.first_date_seen,
            last_date_seen_raw: wmd.last_date_seen_raw,
            last_date_seen: wmd.last_date_seen
        )
      end
    end

    puts "Deleting WM Indicators"
    MIndicator.where(from_weather_map: true).find_in_batches.with_index do |group,batch|
      puts "Processing WM Indicator group #{batch}"
      group.each(&:destroy)
    end

    puts "Dropping Weather Map Table"
    drop_table :weather_map_data
  end
end
