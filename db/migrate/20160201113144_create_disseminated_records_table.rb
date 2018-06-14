class CreateDisseminatedRecordsTable < ActiveRecord::Migration
  def up
    create_table :disseminated_records do |t|
      t.string     :stix_id, null: false
      t.datetime   :xml_updated_at
      t.datetime   :disseminated_at
    end

    add_index :disseminated_records, :xml_updated_at
  end

  def down
    drop_table :disseminated_records
  end
end
