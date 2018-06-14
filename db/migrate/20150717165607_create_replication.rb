class CreateReplication < ActiveRecord::Migration
  def change
    create_table :replications do |t|
      t.string :version
      t.string :url
      t.string :api_key
      t.string :api_key_hash
    end
  end
end
