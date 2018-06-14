class CreateConcurrentUserTable < ActiveRecord::Migration
  def up
    if !ActiveRecord::Base.connection.table_exists?(:user_sessions)
      create_table :user_sessions do |t|
        t.string :username
        t.string :session_id
        t.datetime :session_updated_at
      end
    end
  end

  def down
    if ActiveRecord::Base.connection.table_exists?(:user_sessions)
      drop_table :user_sessions
    end
  end
end
