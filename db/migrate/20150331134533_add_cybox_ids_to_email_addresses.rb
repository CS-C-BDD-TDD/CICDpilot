class AddCyboxIdsToEmailAddresses < ActiveRecord::Migration
  def change
    add_column :cybox_email_messages, :from_cybox_object_id, :string
    add_column :cybox_email_messages, :reply_to_cybox_object_id, :string
    add_column :cybox_email_messages, :sender_cybox_object_id, :string
  end
end
