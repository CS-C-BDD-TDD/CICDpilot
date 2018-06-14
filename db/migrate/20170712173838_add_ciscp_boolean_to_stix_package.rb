class AddCiscpBooleanToStixPackage < ActiveRecord::Migration
  def up
    add_column :stix_packages, :is_ciscp, :boolean, :default => false
  end
  def down
    remove_column :stix_packages, :is_ciscp
  end
end
