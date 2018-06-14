class R5Tracking < ActiveRecord::Migration
  def change
    create_table :r5tracking do |t|
      t.string "table"
      t.integer "old_id"
    end
    create_table :r5destinations do |t|
      t.string "r5table"
      t.integer "r5id"
      t.string "r6table"
      t.integer "r6id"
    end
  end
end
