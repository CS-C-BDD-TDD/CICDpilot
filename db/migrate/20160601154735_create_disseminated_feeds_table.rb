class CreateDisseminatedFeedsTable < ActiveRecord::Migration
  def up
    create_table :disseminated_feeds do |t|
      t.integer    :disseminate_id
      t.string     :feed
    end
  end

  def down
    drop_table :disseminated_feeds
  end
end
