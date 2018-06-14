class KillChainSerializer < Serializer
  attributes :id,
             :definer,
             :guid,
             :kill_chain_name,
             :reference,
             :stix_kill_chain_id,
             :is_default

  associate :kill_chain_phases, {
    as: :stix_kill_chain_phases, 
    except: [
      :created_at, 
      :updated_at
    ]
  }

end