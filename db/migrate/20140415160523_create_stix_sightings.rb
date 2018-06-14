class CreateStixSightings < ActiveRecord::Migration
  def change
    create_table :stix_sightings do |t|
      t.text :description
      t.datetime :sighted_at
      t.string :stix_indicator_id
    end

    add_index :stix_sightings, :stix_indicator_id
  end
end
