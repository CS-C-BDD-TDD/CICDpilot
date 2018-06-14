class ModifyColumnsAddedToCyboxHttpSession < ActiveRecord::Migration
  def change
    rename_column :cybox_http_sessions, :host,
        :domain_name
    remove_column :cybox_http_sessions, :layer4_protocol
  end
end
