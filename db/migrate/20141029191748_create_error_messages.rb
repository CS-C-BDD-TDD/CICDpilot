class CreateErrorMessages < ActiveRecord::Migration
  def change
    create_table :error_messages do |t|
      t.text       :admin_description              # Can store stack traces
      t.string     :description
      t.boolean    :is_warning, default: false
      t.integer    :source_id
      t.string     :source_type
      t.timestamps
    end

    add_index :error_messages, :source_id
  end
end
