class Ttp < ActiveRecord::Base

  has_many :stix_markings, primary_key: :guid, as: :remote_object, dependent: :destroy
  accepts_nested_attributes_for :stix_markings, allow_destroy: true
  
  has_many :isa_marking_structures, primary_key: :stix_id, through: :stix_markings
  has_many :isa_assertion_structures, primary_key: :stix_id, through: :stix_markings

  # remove audit is on the higher object, ie: the one the item is being removed from
  has_many :ttp_packages, primary_key: :stix_id, foreign_key: :stix_ttp_id
  has_many :stix_packages, through: :ttp_packages

  has_many :indicator_ttps, primary_key: :stix_id, foreign_key: :stix_ttp_id
  has_many :indicators, through: :indicator_ttps
  
  has_many :ttp_attack_patterns, primary_key: :stix_id, foreign_key: :stix_ttp_id, dependent: :destroy
  has_many :attack_patterns, through: :ttp_attack_patterns, before_remove: :audit_attack_pattern_removal

  has_many :ttp_exploit_targets, primary_key: :stix_id, foreign_key: :stix_ttp_id, dependent: :destroy
  has_many :exploit_targets, through: :ttp_exploit_targets, before_remove: :audit_exploit_target_removal

  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  belongs_to :created_by_user, class_name: 'User', primary_key: :guid, foreign_key: :created_by_user_guid
  belongs_to :updated_by_user, class_name: 'User', primary_key: :guid, foreign_key: :updated_by_user_guid
  belongs_to :created_by_organization, class_name: 'Organization', primary_key: :guid, foreign_key: :created_by_organization_guid
  belongs_to :updated_by_organization, class_name: 'Organization', primary_key: :guid, foreign_key: :updated_by_organization_guid

  belongs_to :acs_set, primary_key: :guid

  before_save :set_controlled_structures

  include AcsDefault
  include Auditable
  include Guidable
  include Stixable
  include Ingestible
  include Serialized
  include ClassifiedObject
  include Transferable

  CLASSIFICATION_CONTAINER_OF = [:attack_patterns, :exploit_targets]

  CLASSIFICATION_CONTAINED_BY = [:stix_packages, :indicators]
    
  # Trickles down the disseminated feed value to all of the associated objects
  def trickledown_feed
    begin
      associations = ["exploit_targets", "attack_patterns"]
      associations.each do |a|
        object = self.send a
        if object.present? && self.feeds.present?
          object.each do |x| 
            x.update_column(:feeds, self.feeds) 
            x.try(:trickledown_feed)
          end 
        end
      end
    rescue Exception => e
      ex_msg = "Exception during trickledown_feed on: " + self.class.name    
      ExceptionLogger.debug("#{ex_msg}" + ". #{e.to_s}")
    end
  end     

  def self.ingest(uploader, obj, parent = nil)
    x = Ttp.find_by_stix_id(obj.stix_id)
    if x.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_warning(uploader, "TTP of #{obj.stix_id} already exists.  Skipping.  Select overwrite to add")
      return x
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      if !obj.stix_id.nil?
        x = Ttp.find_by_stix_id(obj.stix_id + Setting.READ_ONLY_EXT)
      end
    end

    if x.present?
      x.stix_markings.destroy_all
      x.ttp_attack_patterns.destroy_all
      x.ttp_exploit_targets.destroy_all
      x.acs_set_id = nil
    end

    if x.present? && (uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite))
      x.destroy
      x = nil
    end

    x ||= Ttp.new
    if (uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)) && !obj.stix_id.nil?
      x.stix_id = obj.stix_id + Setting.READ_ONLY_EXT
      if (defined? obj.guid)  
        x.guid = obj.guid + Setting.READ_ONLY_EXT
      else 
        x.guid = SecureRandom.uuid + Setting.READ_ONLY_EXT
      end
    else 
      x.stix_id = obj.stix_id
    end
    x.stix_timestamp = obj.respond_to?(:stix_timestamp) ? obj.stix_timestamp : nil

    unless parent.nil?
      x.created_by_user_guid = parent.guid
      x.created_by_organization_guid = parent.organization_guid
      x.updated_by_user_guid = parent.guid
      x.updated_by_organization_guid = parent.organization_guid
    end

    x.read_only = uploader.read_only

    x
  rescue
    IngestUtilities.add_warning(uploader, "Failed to build TTP (#{obj.stix_id})")
    x
  end

  def set_controlled_structures
    if self.stix_markings.present?
      self.stix_markings.each { |sm| set_controlled_structure(sm) }
    end
    set_ap_controlled_structures
  end

  def set_controlled_structure(sm)
    if sm.present?
      sm.controlled_structure =
          "//stix:TTP[@id='#{self.stix_id}']/"
      
      sm.controlled_structure += 'descendant-or-self::node()'
      sm.controlled_structure += " | #{sm.controlled_structure}/@*"
    end
  end

  def set_ap_controlled_structures
    if self.attack_patterns.present?
      self.attack_patterns.each { |ap|
        if ap.stix_markings.present?
          ap.stix_markings.each { |sm|
            ap.set_controlled_structure(sm, self.stix_id)
          }
        end
      }
    end
  end

  def indicator_stix_ids=(stix_ids)
    self.indicator_ids = Indicator.where(stix_id: stix_ids).pluck(:id)
  end

  def stix_package_stix_ids=(stix_ids)
    self.stix_package_ids = StixPackage.where(stix_id: stix_ids).pluck(:id)
  end

  def attack_pattern_stix_ids=(stix_ids)
    self.attack_pattern_ids = AttackPattern.where(stix_id: stix_ids).pluck(:id)
  end

  def exploit_target_stix_ids=(stix_ids)
    self.exploit_target_ids = ExploitTarget.where(stix_id: stix_ids).pluck(:id)
  end

  def audit_attack_pattern_removal(item)
    audit = Audit.basic
    audit.message = "Attack Pattern '#{item.stix_id}' removed from TTP '#{self.stix_id}'"
    audit.audit_type = :ttp_attack_pattern_unlink
    ind_audit = audit.dup
    ind_audit.item = item
    item.audits << ind_audit
    ta_audit = audit.dup
    ta_audit.item = self
    self.audits << ta_audit
  end

  def audit_exploit_target_removal(item)
    audit = Audit.basic
    audit.message = "Exploit Target '#{item.stix_id}' removed from TTP '#{self.stix_id}'"
    audit.audit_type = :ttp_exploit_target_unlink
    ind_audit = audit.dup
    ind_audit.item = item
    item.audits << ind_audit
    ta_audit = audit.dup
    ta_audit.item = self
    self.audits << ta_audit
  end

  def solr_stix_id
    self.stix_id
  end

private

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    text :stix_id, as: :text_exact
    text :solr_stix_id, as: :text_dash_separate
    string :stix_id
    text :guid, as: :text_exactm
    time :updated_at, stored: false
    time :created_at, stored: false

  end

end
