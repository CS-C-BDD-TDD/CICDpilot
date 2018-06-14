class AddCirUserRequirements < ActiveRecord::Migration
  class MUser < ActiveRecord::Base; self.table_name = :users; end
  class MPassword < ActiveRecord::Base; self.table_name = :passwords; end

  def up
    create_table :passwords do |t|
      t.string :password_hash
      t.string :password_salt
      t.boolean :requires_change, default: false
      t.string :user_guid
      t.timestamps
    end

    MUser.all.each do |user|
      MPassword.create(password_hash: user.password_hash,password_salt: user.password_salt, user_guid: user.guid)
    end
  end

  def down
    drop_table :passwords
  end
end