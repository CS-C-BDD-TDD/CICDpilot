class CreateTags < ActiveRecord::Migration
  class Tag < ActiveRecord::Base; end
  def up
    create_table :tags do |t|
      t.string   :name, :null => false
      t.string   :name_normalized, :null => false
      t.string   :user_guid # FK to USERS table
      t.integer  :r5_collection_id
      t.timestamps
    end
    Tag.create!(name: 'excluded-from-e1', name_normalized: 'excluded-from-e1')
  end
  def down
    drop_table :tags
  end
end
