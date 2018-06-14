class SetCyboxwinregkeyidToCyboxObjectId < ActiveRecord::Migration
  def change
  	rename_column :cybox_win_registry_values, :cybox_win_reg_key_id, :cybox_object_id
  end
end
