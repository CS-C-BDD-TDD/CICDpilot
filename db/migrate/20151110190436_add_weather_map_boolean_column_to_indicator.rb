class AddWeatherMapBooleanColumnToIndicator < ActiveRecord::Migration
  class MIndicator < ActiveRecord::Base;self.table_name = :stix_indicators end
  class MWeatherMapData < ActiveRecord::Base;self.table_name = :weather_map_data end

  def up
    add_column :stix_indicators,:from_weather_map,:boolean, default: false
    add_index :stix_indicators,:from_weather_map


    indicator = Arel::Table.new(:stix_indicators)
    observables = Arel::Table.new(:cybox_observables)
    addresses = Arel::Table.new(:cybox_addresses)
    wmd = Arel::Table.new(:weather_map_data)

    offset = 0
    limit = 1000

    while 1
      indicators = MIndicator.find_by_sql(
          indicator.project(indicator[Arel.sql("*")]).
              join(observables).on(observables[:stix_indicator_id].eq(indicator[:stix_id])).
              join(addresses).on(addresses[:cybox_object_id].eq(observables[:remote_object_id])).
              join(wmd).on(wmd[:ipv4_address_normalized].eq(addresses[:address_value_normalized])).
              take(limit).skip(offset).order(indicator[:created_at]).to_sql
      )
      break if indicators.count <= 0
      indicators.each do |ind|
        ind.from_weather_map = true
        ind.save
      end
      offset += limit
    end
  end

  def down
    remove_column :stix_indicators, :from_weather_map
  end
end
