class KillChainPhase < ActiveRecord::Base
  self.table_name = "stix_kill_chain_phases"
  include Auditable
  include Guidable
  include Ingestible
  include Transferable

  attr_accessor :alt_stix_id    # Used during STIX file upload processing

  belongs_to :kill_chain, primary_key: :stix_kill_chain_id, foreign_key: :stix_kill_chain_id
  has_many :kill_chain_refs, primary_key: :stix_kill_chain_phase_id, foreign_key: :stix_kill_chain_phase_id, dependent: :destroy
  default_scope { order('ordinality asc') }
  
end
