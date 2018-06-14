class AddRemoteGuidToUsers < ActiveRecord::Migration
  def change
    add_column :users, :remote_guid, :string
  end
end
