class AddOrganizationTokenToOrganizations < ActiveRecord::Migration
  def up
    add_column :organizations, :organization_token, :string
  end

  def down
    remove_column :organizations, :organization_token
  end
end
