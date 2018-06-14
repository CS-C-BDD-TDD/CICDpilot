class CreateYaraRules < ActiveRecord::Migration
  def change
    create_table :legacy_yara_rules do |t|
      t.string :name
      t.integer :string_location
      t.string :string
      t.text :rule
      t.string :indicator_guid
    end
  end
end
