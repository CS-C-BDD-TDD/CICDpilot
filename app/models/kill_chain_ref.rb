class KillChainRef < ActiveRecord::Base
  self.table_name = "stix_kill_chain_refs"
  include Auditable
  include Guidable
  include Transferable

  before_save :update_kill_chain_id

  belongs_to :kill_chain,
             primary_key: :stix_kill_chain_id,
             foreign_key: :stix_kill_chain_id
  belongs_to :kill_chain_phase,
             primary_key: :stix_kill_chain_phase_id,
             foreign_key: :stix_kill_chain_phase_id
  belongs_to :remote_object,
             primary_key: :stix_id,
             foreign_key: :remote_object_id,
             foreign_type: :remote_object_type,
             polymorphic: true

  # Actually loads Kill Chain Phase references (attached to an Indicator).
  # Because the kill chain phases need to be mapped back to the kill chain
  # phases that were defined at the Package level, the parent that's passed
  # in is the Package (and not the Indicator).
  #
  # It is the responsibility of the caller to attach the ref to the
  # Indicator.

  def self.ingest(uploader, obj, parent = nil)
    r = KillChainRef.new
    r.remote_object_type = 'Indicator'
    r.stix_kill_chain_id = obj.stix_kill_chain_id
    r.stix_kill_chain_phase_id = obj.stix_id
    # Adjust ref stix IDs if necessary
    r = r.adjust_kill_chain_ref(uploader, obj, r, parent)

    if r.stix_kill_chain_phase_id.nil? || r.stix_kill_chain_id.nil?
      IngestUtilities.add_warning(uploader, 'Skipping Invalid KillChainPhase Reference')
      return nil
    end

    r
  end

  def adjust_kill_chain_ref(uploader, obj, r, pkg)
    # The kill chain must be  valid or it will be set to nil
    kill_chain_id = nil
    # The phase must be in a kill chain or it will be set to nil
    kill_chain_phase_id = nil
    kill_chain_phase_name = obj.name.present? ? obj.name : ''
    default = match_default_kill_chain_name(obj.stix_kill_chain_name)
    if default.nil?
      ex = match_existing_kill_chain_id(r.stix_kill_chain_id)
      if ex.present?
        # Use the existing kill chain that is being referenced and replace
        # phase ids by phase names
        kill_chain_id = ex.stix_kill_chain_id
        ex.kill_chain_phases.each do |p|
          if p.phase_name.downcase == kill_chain_phase_name.downcase ||
              p.stix_kill_chain_phase_id == r.stix_kill_chain_phase_id
            kill_chain_phase_id = p.stix_kill_chain_phase_id
          end
        end
      end
    else
      # Use the default kill chain and replace phase ids by phase names
      kill_chain_id = default.stix_kill_chain_id
      default.kill_chain_phases.each do |p|
        if p.phase_name.downcase == kill_chain_phase_name.downcase ||
            p.stix_kill_chain_phase_id == r.stix_kill_chain_phase_id
          kill_chain_phase_id = p.stix_kill_chain_phase_id
        end
      end
    end
    if pkg.present?
      # Determine if pkg is a hash acting as a dummy package because a
      # package is not being created or an actual StixPackage and access it
      # appropriately.
      uploaded_kill_chains = pkg.class.to_s == 'Hash' ?
          pkg[:uploaded_kill_chains] : pkg.uploaded_kill_chains
      if uploaded_kill_chains.present?
        uploaded_kill_chains.each do |kc|
          if r.stix_kill_chain_id == kc.alt_stix_id ||
              r.stix_kill_chain_id == kc.stix_kill_chain_id
            kill_chain_id = kc.stix_kill_chain_id
            next unless kc.kill_chain_phases.present?
            kc.kill_chain_phases.each do |p|
              if r.stix_kill_chain_phase_id == p.alt_stix_id ||
                  r.stix_kill_chain_phase_id == p.stix_kill_chain_phase_id
                kill_chain_phase_id = p.stix_kill_chain_phase_id
              end
            end
          end
        end
      end
    end
    # Set the id to the correct id or nil
    r.stix_kill_chain_id = kill_chain_id
    # Set the phase id to the correct id or nil
    r.stix_kill_chain_phase_id = kill_chain_phase_id

    r
  end

  def match_default_kill_chain_name(kill_chain_name)
    return nil if kill_chain_name.nil?
    default = ::KillChain.where(is_default: true).first
    if default.present? && default.kill_chain_name.present? &&
        kill_chain_name.downcase == default.kill_chain_name.downcase
      return default
    end

    nil
  end

  def match_existing_kill_chain_id(kill_chain_id)
    return nil if kill_chain_id.nil?
    ex = ::KillChain.where(stix_kill_chain_id: kill_chain_id).first
    if ex.present?
      return ex
    end

    nil
  end

  def update_kill_chain_id
    self.stix_kill_chain_id = self.kill_chain_phase.stix_kill_chain_id
  end
end
