class AddConditionAttributes < ActiveRecord::Migration
  def change
  	add_column :cybox_uris, :uri_condition, :string
  	add_column :cybox_links, :label_condition, :string
  	add_column :cybox_win_registry_keys, :hive_condition, :string
  	add_column :cybox_addresses, :address_condition, :string
  	add_column :cybox_http_sessions, :user_agent_condition, :string
  	add_column :cybox_win_registry_values, :data_condition, :string
  	add_column :cybox_email_messages, :subject_condition, :string
  end
end
