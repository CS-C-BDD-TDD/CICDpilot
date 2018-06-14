class AddLockedToAcsSet < ActiveRecord::Migration
  def change
    add_column :acs_sets, :locked, :boolean, default: false
  end
end
