class AddRemoteIpToAuthenticationLog < ActiveRecord::Migration
  def change
    add_column :authentication_logs, :remote_ip, :string
  end
end
