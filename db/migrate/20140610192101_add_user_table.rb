class AddUserTable < ActiveRecord::Migration
  def up
    create_table :users do |t|
      t.string :username
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.string :password_hash
      t.string :password_salt
      t.string :organization_guid
      t.datetime :locked_at
      t.datetime :logged_in_at
      t.integer :failed_login_attempts, :precision => 38, :scale => 0, :default => 0
      t.datetime :expired_at
      t.datetime :disabled_at
      t.boolean :password_change_required, :precision => 1,  :scale => 0, :default => false
      t.datetime :password_changed_at
      t.datetime :terms_accepted_at
      t.datetime :hidden_at
      t.integer :throttle, :precision => 38, :scale => 0, :default => 0
      t.boolean :machine, :precision => 1,  :scale => 0, :default => false
      t.integer :r5_id
      t.timestamps
    end
  end
end
