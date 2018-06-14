class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.integer "r5_id"
      t.string  "guid"
      t.string  "long_name"
      t.string  "short_name"
      t.text    "contact_info"
      t.string  "category"
      t.integer "releasability_mask", :default => 15
      t.timestamps
    end
  end
end
