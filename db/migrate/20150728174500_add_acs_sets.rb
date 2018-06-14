class AddAcsSets < ActiveRecord::Migration
  class MPermission < ActiveRecord::Base;self.table_name = :permissions;end
  def change
    create_table :acs_sets do |t|
      t.string :name
      t.string :stix_id
      t.string :guid
      t.integer :acs_sets_org_id
      t.string :color
      t.timestamps
    end

    create_table :acs_sets_organizations do |t|
      t.integer :organization_id
      t.integer :acs_set_id
    end

    change_table :organizations do |t|
      t.column :acs_sets_org_id, :integer
    end

    change_table :stix_indicators do |t|
      t.column :acs_set_id, :integer
    end

    change_table :stix_packages do |t|
      t.column :acs_set_id, :integer
    end

    yml = YAML.load_file('config/permissions.yml')
    (yml[Rails.env]||[]).each do |name,attributes|
      if MPermission.find_by_name(name)
        puts "Permission: #{name} already exists."
        next
      end

      MPermission.create(name:name,
                        display_name: attributes['display_name'],
                        description: attributes['description'])
      puts "Permission: #{name} created."
    end
  end
end