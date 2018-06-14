object @kill_chain

attributes :id,
           :definer,
           :guid,
           :kill_chain_name,
           :reference,
           :stix_kill_chain_id,
           :is_default

child :kill_chain_phases do
  extends "kill_chain_phases/index", locals: {associations: locals[:associations]}
end
