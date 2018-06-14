class AddCyboxHashToRegistryValues < ActiveRecord::Migration
  def up
  	add_column :cybox_win_registry_values, :cybox_hash, :string
  end

  def down
  	remove_column :cybox_win_registry_values, :cybox_hash
  end
end
