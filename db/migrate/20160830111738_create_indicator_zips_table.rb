class CreateIndicatorZipsTable < ActiveRecord::Migration
  def up
    create_table :indicator_zips do |t|
      t.integer :uploaded_file_id
      t.integer :indicator_id
    end

    add_index :indicator_zips, :uploaded_file_id
  end

  def down
    drop_table :indicator_zips
  end
end
