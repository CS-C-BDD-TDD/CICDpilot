class CreateStixKillChainsAgain < ActiveRecord::Migration
  def up
    # Drop the original table; it was created in 2014 and never used.
    begin
      rename_table :stix_kill_chains, :old_stix_kill_chains
    rescue
    end

    create_stix_kill_chain_phases
    create_stix_kill_chains
    create_stix_kill_chain_refs

    add_default_kill_chain
  end

  def down
    drop_table :stix_kill_chain_refs
    drop_table :stix_kill_chains
    drop_table :stix_kill_chain_phases

    begin
      rename_table :old_stix_kill_chains, :stix_kill_chains
    rescue
    end
  end

  def add_default_kill_chain
    if ActiveRecord::Base.connection.instance_values["config"][:adapter]=='oracle_enhanced'
      execute "INSERT INTO stix_kill_chains (id, definer, guid, is_default,
                  kill_chain_name, reference, stix_kill_chain_id)
               VALUES (stix_kill_chains_seq.nextval, 'LMCO', 'af3e707f-2fb9-49e5-8c37-14026ca0a5ff', 1,
                       'LM Cyber Kill Chain',
                       'http://www.lockheedmartin.com/content/dam/lockheed/data/corporate/documents/LM-White-Paper-Intel-Driven-Defense.pdf',
                       'stix:KillChain-af3e707f-2fb9-49e5-8c37-14026ca0a5ff')"
 
      execute "INSERT INTO stix_kill_chain_phases (id, phase_name, ordinality, guid,
                  stix_kill_chain_id, stix_kill_chain_phase_id)
               VALUES (stix_kill_chain_phases_seq.nextval, 'Reconnaissance', 1,
                       'af1016d6-a744-4ed7-ac91-00fe2272185a',
                       'stix:KillChain-af3e707f-2fb9-49e5-8c37-14026ca0a5ff',
                       'stix:KillChainPhase-af1016d6-a744-4ed7-ac91-00fe2272185a')"

      execute "INSERT INTO stix_kill_chain_phases (id, phase_name, ordinality, guid,
                  stix_kill_chain_id, stix_kill_chain_phase_id)
               VALUES (stix_kill_chain_phases_seq.nextval, 'Weaponization', 2,
                       '445b4827-3cca-42bd-8421-f2e947133c16',
                       'stix:KillChain-af3e707f-2fb9-49e5-8c37-14026ca0a5ff',
                       'stix:KillChainPhase-445b4827-3cca-42bd-8421-f2e947133c16')"

      execute "INSERT INTO stix_kill_chain_phases (id, phase_name, ordinality, guid,
                  stix_kill_chain_id, stix_kill_chain_phase_id)
               VALUES (stix_kill_chain_phases_seq.nextval, 'Delivery', 3,
                       '79a0e041-9d5f-49bb-ada4-8322622b162d',
                       'stix:KillChain-af3e707f-2fb9-49e5-8c37-14026ca0a5ff',
                       'stix:KillChainPhase-79a0e041-9d5f-49bb-ada4-8322622b162d')"

      execute "INSERT INTO stix_kill_chain_phases (id, phase_name, ordinality, guid,
                  stix_kill_chain_id, stix_kill_chain_phase_id)
               VALUES (stix_kill_chain_phases_seq.nextval, 'Exploitation', 4,
                       'f706e4e7-53d8-44ef-967f-81535c9db7d0',
                       'stix:KillChain-af3e707f-2fb9-49e5-8c37-14026ca0a5ff',
                       'stix:KillChainPhase-f706e4e7-53d8-44ef-967f-81535c9db7d0')"

      execute "INSERT INTO stix_kill_chain_phases (id, phase_name, ordinality, guid,
                  stix_kill_chain_id, stix_kill_chain_phase_id)
               VALUES (stix_kill_chain_phases_seq.nextval, 'Installation', 5,
                       'e1e4e3f7-be3b-4b39-b80a-a593cfd99a4f',
                       'stix:KillChain-af3e707f-2fb9-49e5-8c37-14026ca0a5ff',
                       'stix:KillChainPhase-e1e4e3f7-be3b-4b39-b80a-a593cfd99a4f')"

      execute "INSERT INTO stix_kill_chain_phases (id, phase_name, ordinality, guid,
                  stix_kill_chain_id, stix_kill_chain_phase_id)
               VALUES (stix_kill_chain_phases_seq.nextval, 'Command and Control', 6,
                       'd6dc32b9-2538-4951-8733-3cb9ef1daae2',
                       'stix:KillChain-af3e707f-2fb9-49e5-8c37-14026ca0a5ff',
                       'stix:KillChainPhase-d6dc32b9-2538-4951-8733-3cb9ef1daae2')"

      execute "INSERT INTO stix_kill_chain_phases (id, phase_name, ordinality, guid,
                  stix_kill_chain_id, stix_kill_chain_phase_id)
               VALUES (stix_kill_chain_phases_seq.nextval, 'Actions on Objectives', 7,
                       '786ca8f9-2d9a-4213-b38e-399af4a2e5d6',
                       'stix:KillChain-af3e707f-2fb9-49e5-8c37-14026ca0a5ff',
                       'stix:KillChainPhase-786ca8f9-2d9a-4213-b38e-399af4a2e5d6')"
    else
      execute "INSERT INTO stix_kill_chains (definer, guid, is_default,
                  kill_chain_name, reference, stix_kill_chain_id)
               VALUES ('LMCO', 'af3e707f-2fb9-49e5-8c37-14026ca0a5ff', 't',
                       'LM Cyber Kill Chain',
                       'http://www.lockheedmartin.com/content/dam/lockheed/data/corporate/documents/LM-White-Paper-Intel-Driven-Defense.pdf',
                       'stix:KillChain-af3e707f-2fb9-49e5-8c37-14026ca0a5ff')"
 
      execute "INSERT INTO stix_kill_chain_phases (phase_name, ordinality, guid,
                  stix_kill_chain_id, stix_kill_chain_phase_id)
               VALUES ('Reconnaissance', 1,
                       'af1016d6-a744-4ed7-ac91-00fe2272185a',
                       'stix:KillChain-af3e707f-2fb9-49e5-8c37-14026ca0a5ff',
                       'stix:KillChainPhase-af1016d6-a744-4ed7-ac91-00fe2272185a')"

      execute "INSERT INTO stix_kill_chain_phases (phase_name, ordinality, guid,
                  stix_kill_chain_id, stix_kill_chain_phase_id)
               VALUES ('Weaponization', 2,
                       '445b4827-3cca-42bd-8421-f2e947133c16',
                       'stix:KillChain-af3e707f-2fb9-49e5-8c37-14026ca0a5ff',
                       'stix:KillChainPhase-445b4827-3cca-42bd-8421-f2e947133c16')"

      execute "INSERT INTO stix_kill_chain_phases (phase_name, ordinality, guid,
                  stix_kill_chain_id, stix_kill_chain_phase_id)
               VALUES ('Delivery', 3,
                       '79a0e041-9d5f-49bb-ada4-8322622b162d',
                       'stix:KillChain-af3e707f-2fb9-49e5-8c37-14026ca0a5ff',
                       'stix:KillChainPhase-79a0e041-9d5f-49bb-ada4-8322622b162d')"

      execute "INSERT INTO stix_kill_chain_phases (phase_name, ordinality, guid,
                  stix_kill_chain_id, stix_kill_chain_phase_id)
               VALUES ('Exploitation', 4,
                       'f706e4e7-53d8-44ef-967f-81535c9db7d0',
                       'stix:KillChain-af3e707f-2fb9-49e5-8c37-14026ca0a5ff',
                       'stix:KillChainPhase-f706e4e7-53d8-44ef-967f-81535c9db7d0')"

      execute "INSERT INTO stix_kill_chain_phases (phase_name, ordinality, guid,
                  stix_kill_chain_id, stix_kill_chain_phase_id)
               VALUES ('Installation', 5,
                       'e1e4e3f7-be3b-4b39-b80a-a593cfd99a4f',
                       'stix:KillChain-af3e707f-2fb9-49e5-8c37-14026ca0a5ff',
                       'stix:KillChainPhase-e1e4e3f7-be3b-4b39-b80a-a593cfd99a4f')"

      execute "INSERT INTO stix_kill_chain_phases (phase_name, ordinality, guid,
                  stix_kill_chain_id, stix_kill_chain_phase_id)
               VALUES ('Command and Control', 6,
                       'd6dc32b9-2538-4951-8733-3cb9ef1daae2',
                       'stix:KillChain-af3e707f-2fb9-49e5-8c37-14026ca0a5ff',
                       'stix:KillChainPhase-d6dc32b9-2538-4951-8733-3cb9ef1daae2')"

      execute "INSERT INTO stix_kill_chain_phases (phase_name, ordinality, guid,
                  stix_kill_chain_id, stix_kill_chain_phase_id)
               VALUES ('Actions on Objectives', 7,
                       '786ca8f9-2d9a-4213-b38e-399af4a2e5d6',
                       'stix:KillChain-af3e707f-2fb9-49e5-8c37-14026ca0a5ff',
                       'stix:KillChainPhase-786ca8f9-2d9a-4213-b38e-399af4a2e5d6')"
    end
  end

  def create_stix_kill_chain_phases
    create_table :stix_kill_chain_phases do |t|
      t.string  :guid, null: false                     # CIAP Unique Identifier
      t.integer :ordinality                            # Order within a list
      t.string  :phase_name, null: false               # The name of the phase
      t.string  :stix_kill_chain_id, null: false       # FK to STIX_KILL_CHAINS
      t.string  :stix_kill_chain_phase_id, null: false # The STIX_ID
      t.timestamps
    end

    add_index :stix_kill_chain_phases, :stix_kill_chain_id
    add_index :stix_kill_chain_phases, :stix_kill_chain_phase_id
  end

  def create_stix_kill_chains
    create_table :stix_kill_chains do |t|
      t.string  :definer                              # Defined by?
      t.string  :guid, null: false                    # CIAP Unique Identifier
      t.string  :kill_chain_name, null: false         # The name of the chain
      t.string  :reference                            # Defined where? PDF?
      t.string  :stix_kill_chain_id, null: false      # The STIX ID.
      t.boolean :is_default, null: false, default: false
      t.timestamps
    end

    add_index :stix_kill_chains, :stix_kill_chain_id
  end

  def create_stix_kill_chain_refs
    create_table :stix_kill_chain_refs do |t|
      t.string  :guid, null: false
      t.string :stix_kill_chain_id, null: false
      t.string :stix_kill_chain_phase_id, null: false
      t.string :remote_object_id, null: false
      t.string :remote_object_type, null: false
      t.timestamps
    end

    add_index :stix_kill_chain_refs, :remote_object_id
  end

end
