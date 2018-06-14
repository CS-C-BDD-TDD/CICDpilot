class CreateSectionHashes < ActiveRecord::Migration
  def change
    create_table :legacy_section_hashes do |t|
      t.string :indicator_guid
      t.string :hsh
      t.string :name
      t.string :ord
      t.string :size
      t.string :hash_type
      t.string :vsize
      t.timestamps
    end
  end
end
