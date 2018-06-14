class AddWeatherMapDataRows < ActiveRecord::Migration
  def change
    add_column :weather_map_data,:combined_score, :string
    add_column :weather_map_data,:category_list, :string, :limit => 500
    add_index :audit_logs, [:item_type_audited, :item_guid_audited]
  end
end
