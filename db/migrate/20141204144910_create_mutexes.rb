class CreateMutexes < ActiveRecord::Migration
  def change
    create_table :cybox_mutexes do |t|
      t.string :cybox_object_id
      t.string :cybox_hash
      t.string :name
      t.string :name_condition, default: 'Equals'
      t.string :guid
      
      t.timestamps
    end

    add_index :cybox_mutexes, :cybox_object_id
    add_index :cybox_mutexes, :guid
  end
end
