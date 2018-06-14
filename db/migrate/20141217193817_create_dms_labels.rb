class CreateDmsLabels < ActiveRecord::Migration
  def change
    create_table :dms_labels do |t|
      t.datetime  :dms_record_date
      t.integer   :dms_record_id
      t.boolean   :is_vetted, default: false
      t.string    :remote_object_id
      t.string    :remote_object_type
      t.string    :source
      t.integer   :version_id
      t.timestamps
    end

    add_index :dms_labels, :dms_record_id
  end
end
