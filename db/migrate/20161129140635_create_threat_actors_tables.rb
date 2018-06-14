class CreateThreatActorsTables < ActiveRecord::Migration
  def up
    create_table :threat_actors do |t|
      t.string :title
      t.string :title_c
      t.text   :description
      t.string :description_c
      t.text   :short_description
      t.string :short_description_c
      t.string :identity_name
      t.string :identity_name_c
      t.string :stix_id
      t.string :portion_marking
      t.timestamps
      t.string :guid
      t.string :created_by_user_guid
      t.string :updated_by_user_guid
      t.string :created_by_organization_guid
      t.string :updated_by_organization_guid
      t.integer :acs_set_id
      t.boolean :read_only, :default => false
    end

    add_index :threat_actors, :guid
    add_index :threat_actors, :stix_id

    create_table :indicators_threat_actors do |t|
      t.string :threat_actor_id
      t.string :stix_indicator_id
      t.timestamps
      t.string :guid
	    t.string :user_guid
    end

    add_index :indicators_threat_actors, :threat_actor_id
    add_index :indicators_threat_actors, :stix_indicator_id
    add_index :indicators_threat_actors, :guid
  end

  def down
    drop_table :threat_actors
    drop_table :indicators_threat_actors
  end
end

