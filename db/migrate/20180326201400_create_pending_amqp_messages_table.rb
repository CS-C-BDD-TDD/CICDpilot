class CreatePendingAmqpMessagesTable < ActiveRecord::Migration
  def change
    create_table :pending_amqp_messages do |t|
      t.boolean :is_stix_xml, null: false
      t.string :transfer_category, null: true
      t.string :repl_type, null: true
      t.binary :message_data, null: false
      t.binary :string_props, null: false
      t.timestamp :last_attempted, null: true
      t.integer :attempt_count, null: false, default: 0
      t.timestamps null: false
    end
  end
end
