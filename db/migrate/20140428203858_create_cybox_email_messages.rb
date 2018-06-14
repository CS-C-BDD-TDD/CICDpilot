class CreateCyboxEmailMessages < ActiveRecord::Migration
  def change
    create_table :cybox_email_messages do |t|
      t.datetime :created_at
      t.string :cybox_hash
      t.string :cybox_object_id
      t.datetime :email_date
      t.boolean :from_is_spoofed, :default => false
      t.string :from_raw
      t.string :from_normalized
      t.string :message_id
      t.text :raw_body
      t.text :raw_header
      t.string :reply_to_raw
      t.string :reply_to_normalized
      t.boolean :sender_is_spoofed, :default => false
      t.string :sender_raw
      t.string :sender_normalized
      t.string :subject
      t.datetime :updated_at
      t.string :x_mailer
      t.string :x_originating_ip
    end

    add_index :cybox_email_messages, :cybox_object_id
  end
end
