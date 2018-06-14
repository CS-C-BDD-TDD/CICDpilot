class CreateAisStatisticsTable < ActiveRecord::Migration
  def up
    if !ActiveRecord::Base.connection.table_exists?(:ais_statistics)
      create_table :ais_statistics do |t|
        t.string :stix_package_stix_id
        t.string :stix_package_original_id
        t.string :uploaded_file_id
        t.string :feeds
        t.string :messages
        t.string :ais_uid
        t.string :guid
        t.integer :indicator_amount
        t.boolean :flare_in_status
        t.boolean :ciap_status
        t.boolean :ecis_status
        t.boolean :flare_out_status
        t.boolean :ecis_status_hr
        t.boolean :flare_out_status_hr
        t.datetime :dissemination_time
        t.datetime :dissemination_time_hr
        t.datetime :received_time
        t.timestamps :null => true
      end

      add_index :ais_statistics, :guid
      add_index :ais_statistics, :ais_uid
    end
  end

  def down
    if ActiveRecord::Base.connection.table_exists?(:ais_statistics)
      remove_index :ais_statistics, :guid
      remove_index :ais_statistics, :ais_uid
      drop_table :ais_statistics
    end

    if ActiveRecord::Base.connection.table_exists?(:ais_statuses)
      remove_index :ais_statuses, :guid
      remove_index :ais_statuses, :ais_uid
      drop_table :ais_statuses
    end
  end

end
