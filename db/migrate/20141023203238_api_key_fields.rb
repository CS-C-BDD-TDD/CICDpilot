class ApiKeyFields < ActiveRecord::Migration
  def change
    add_column :users, :api_key, :string
    add_column :users, :api_key_secret_encrypted, :string
  end
end
