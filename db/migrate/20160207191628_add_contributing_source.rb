class AddContributingSource < ActiveRecord::Migration
  def change
    create_table :contributing_sources do |t|
      t.string :organization_names
      t.string :countries
      t.string :administrative_areas
      t.string :stix_package_stix_id
      t.string :guid
      t.string :organization_info
    end
  end
end
