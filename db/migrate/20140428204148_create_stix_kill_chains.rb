class CreateStixKillChains < ActiveRecord::Migration
  def change
    create_table :stix_kill_chains do |t|
      t.string :kill_chain_id
      t.string :kill_chain_name
      t.integer :ordinality
      t.string :phase_id
      t.string :phase_name
      t.string :remote_object_id
      t.string :remote_object_type
    end

    add_index :stix_kill_chains, :remote_object_id
  end
end
