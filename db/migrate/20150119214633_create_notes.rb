class CreateNotes < ActiveRecord::Migration
  def change
    create_table :notes do |t|
      t.string :guid
      t.string :target_class
      t.string :target_guid
      t.string :user_guid
      t.text :note
      t.string :justification
      t.timestamps
    end
  end
end
