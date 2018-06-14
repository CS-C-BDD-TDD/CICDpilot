class CreateEmailLinksTable < ActiveRecord::Migration
  def up
    create_table :email_links do |t|
      t.string :email_message_id
      t.string :link_id
    end

    create_table :email_uris do |t|
      t.string :email_message_id
      t.string :uri_id
    end
  end

  def down
    drop_table :email_links
    drop_table :email_uris
  end
end
