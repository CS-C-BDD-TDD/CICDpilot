class CreateExports < ActiveRecord::Migration
  class MTag < ActiveRecord::Base; self.table_name = 'tags'; end
  def change
    create_table :exported_indicators do |t|
      t.string :system
      t.string :color
      t.string :guid
      t.datetime :exported_at
      t.text :description

      t.string :indicator_id
      t.string :user_id
    end
  end
end