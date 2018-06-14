class KillChain < ActiveRecord::Base
  self.table_name = "stix_kill_chains"
  include Auditable
  include Guidable
  include Ingestible
  include Serialized
  include Transferable
  
  attr_accessor :alt_stix_id    # Used during STIX file upload processing

  has_many :kill_chain_phases, primary_key: :stix_kill_chain_id, foreign_key: :stix_kill_chain_id, dependent: :destroy
  has_many :kill_chain_refs, primary_key: :stix_kill_chain_id, foreign_key: :stix_kill_chain_id, dependent: :destroy

  # Creates new kill chain and phase definitions only if the kill chain 
  # does NOT match the default Lockheed Martin Kill Chain. If does match
  # the default, then it records the alternate STIX IDs to allow the
  # kill chain references to be properly mapped back later.

  def self.ingest(uploader, obj, parent = nil)
    x = KillChain.new
    HumanReview.adjust(obj, uploader)
    x.definer = obj.definer
    x.is_default = false
    x.kill_chain_name = obj.name
    x.reference = obj.reference
    x.stix_kill_chain_id = obj.stix_id
    default = match_default_kill_chain?(x)
    if default.nil?
      ex = match_existing_kill_chain?(x)
      if ex.present?
        # Use the existing kill chain that is being referenced
        return ex
      else
        # Create a new kill chain and its associated phases
        if obj.phases.present?
          obj.phases.each do |op|
            p = ::KillChainPhase.new
            p.phase_name = op.name
            p.ordinality = op.ordinality
            p.stix_kill_chain_phase_id = op.stix_id
            p.stix_kill_chain_id = op.stix_id
            x.kill_chain_phases << p
          end
        end
        return x
      end
    else
      # Use the default kill chain, but temporarily save mapping information
      x.stix_kill_chain_id = obj.stix_id
      default.kill_chain_phases.each do |p|
        if obj.phases.present?
          obj.phases.each do |op|
            if p.phase_name.downcase == op.name.downcase
              p.alt_stix_id = op.stix_id
            end
          end
        end
      end
      return default
    end
  end

  def self.match_default_kill_chain?(x)
    default = KillChain.where(is_default: true).first
    if x.kill_chain_name.downcase == default.kill_chain_name.downcase
      return default
    end

    nil
  end

  def self.match_existing_kill_chain?(x)
    ex = KillChain.where(stix_kill_chain_id: x.stix_kill_chain_id).first
    if ex.present?
      return ex 
    end

    nil
  end
end
