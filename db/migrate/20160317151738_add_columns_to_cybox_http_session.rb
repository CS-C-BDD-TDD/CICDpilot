class AddColumnsToCyboxHttpSession < ActiveRecord::Migration
  def change
    add_column :cybox_http_sessions, :host, :string
    add_column :cybox_http_sessions, :port, :string
    add_column :cybox_http_sessions, :layer4_protocol, :string
    add_column :cybox_http_sessions, :referer, :string
    add_column :cybox_http_sessions, :pragma, :string
  end
end
