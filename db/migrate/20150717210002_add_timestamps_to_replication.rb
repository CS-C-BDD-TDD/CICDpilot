class AddTimestampsToReplication < ActiveRecord::Migration
  def change
    add_column :replications, :updated_at, :date
    add_column :replications, :created_at, :date
  end
end
