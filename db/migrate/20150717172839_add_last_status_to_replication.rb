class AddLastStatusToReplication < ActiveRecord::Migration
  def change
    add_column :replications, :last_status, :string
  end
end
