class CreateDisseminationQueueTable < ActiveRecord::Migration
  def up
    create_table :dissemination_queue do |t|
      t.string :original_input_id
      t.string :finished_feeds
      t.timestamp :updated
      t.timestamps
    end
  end

  def down
    drop_table :dissemination_queue
  end
end
