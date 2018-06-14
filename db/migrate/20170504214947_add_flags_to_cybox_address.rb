class AddFlagsToCyboxAddress < ActiveRecord::Migration
  def up
  	add_column :cybox_addresses, :is_source, :boolean
  	add_column :cybox_addresses, :is_destination, :boolean
  	add_column :cybox_addresses, :is_spoofed, :boolean
  end
  def down
  	remove_column :cybox_addresses, :is_spoofed
  	remove_column :cybox_addresses, :is_destination
  	remove_column :cybox_addresses, :is_source
  end
end
