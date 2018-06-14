class ThreatActor < ActiveRecord::Base

  has_many :stix_markings, primary_key: :guid, as: :remote_object, dependent: :destroy
  accepts_nested_attributes_for :stix_markings, allow_destroy: true
  
  has_many :indicators_threat_actors, primary_key: :stix_id, foreign_key: :threat_actor_id, dependent: :destroy
  has_many :indicators, through: :indicators_threat_actors, before_remove: :audit_indicator_removal, after_remove: :reset_threat_actor_value_on_indicator
  belongs_to :created_by_user, class_name: 'User', primary_key: :guid, foreign_key: :created_by_user_guid
  belongs_to :updated_by_user, class_name: 'User', primary_key: :guid, foreign_key: :updated_by_user_guid
  belongs_to :created_by_organization, class_name: 'Organization', primary_key: :guid, foreign_key: :created_by_organization_guid
  belongs_to :updated_by_organization, class_name: 'Organization', primary_key: :guid, foreign_key: :updated_by_organization_guid

  has_many :isa_marking_structures, primary_key: :stix_id, through: :stix_markings
  has_many :isa_assertion_structures, primary_key: :stix_id, through: :stix_markings

  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  belongs_to :acs_set, primary_key: :guid

#  before_save :set_controlled_structures

  validates_presence_of :title
  after_commit :set_threat_actor_value_on_indicator

  include AcsDefault
  include Auditable
  include Guidable
  include Stixable
  include Ingestible
  include Serialized
  include ClassifiedObject  
  include Transferable
  
  # Trickles down the disseminated feed value to all of the associated objects
  def trickledown_feed
    begin
      associations = ["indicators"]
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
  end

  def indicator_stix_ids=(stix_ids)
    self.indicator_ids = Indicator.where(stix_id: stix_ids).pluck(:id)
  end

#  def set_controlled_structures
#    if self.stix_markings.present?
#      self.stix_markings.each { |sm| set_controlled_structure(sm) }
#    end
#  end
#
#  def set_controlled_structure(sm)
#    if sm.present?
#      return if sm.remote_object_field == 'party_name' ||
#          (sm.remote_object_field.nil? &&
#              sm.ais_consent_marking_structure.present?)
#      sm.controlled_structure =
#          "//stix:STIX_Package[@id='#{self.stix_id}']/"
#      if sm.remote_object_field.present?
#        case sm.remote_object_field
#          when 'title'
#            sm.controlled_structure +=
#                'stix:STIX_Header/stix:Title/'
#          when 'description'
#            sm.controlled_structure +=
#                'stix:STIX_Header/stix:Description/'
#          when 'short_description'
#            sm.controlled_structure +=
#                'stix:STIX_Header/stix:Short_Description/'
#          when 'package_intent'
#            sm.controlled_structure +=
#                'stix:STIX_Header/stix:Package_Intent/'
#          else
#            sm.controlled_structure = nil
#            return
#        end
#      end
#      sm.controlled_structure += 'descendant-or-self::node()'
#      sm.controlled_structure += "| #{sm.controlled_structure}/@*"
#    end
#  end

  def to_pmap
    export ||= ''
    self.indicators.each do |ind|
      next if ind.system_tags.where(name: "excluded-from-e1").any?
      ind.addresses.each do |ip|
        next unless Address.valid_ipv4_value?(ip.address_value_raw)
        justification = pmap_reason_added(nil)
        export += ("#{ip.address_value_normalized}\t#{justification}\n")
      end
    end
    export
  end

  def to_ipset
    export ||= ''
    self.indicators.each do |ind|
      next if ind.system_tags.where(name: "excluded-from-e1").any?
      ind.addresses.each do |ip|
        next unless Address.valid_ipv4_value?(ip.address_value_raw)
        ip_obj = IPAddress::IPv4.new(ip.address_value_raw.strip)
        if ip_obj.prefix == 32
          export += "#{ip_obj.address}/32\n"
        else
          ip_obj.hosts.each do |h|
            export += h.address + "/32\n"
          end
        end
      end
    end
    export
  end

  CLASSIFICATION_CONTAINER_OF = [:indicators]
private
  def pmap_reason_added(reason_added)
    return reason_added.split.join(" ")[0..255] if reason_added
    return 'no reason given'
  end

  def set_threat_actor_value_on_indicator
    self.indicators.each do |indicator| 
      indicator.set_threat_actor_value
    end 
  end 
  
  def reset_threat_actor_value_on_indicator(item)
      item.set_threat_actor_value
  end

  def audit_indicator_removal(item)
    audit = Audit.basic
    audit.message = "Indicator '#{item.title}' removed threat actor '#{self.title}'"
    audit.audit_type = :indicator_threat_actor_unlink
    ind_audit = audit.dup
    ind_audit.item = item
    item.audits << ind_audit
    ta_audit = audit.dup
    ta_audit.item = self
    self.audits << ta_audit
  end

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    text :title
    string :title
    text :short_description
    string :short_description
    text :stix_id, as: :text_exact
    string :stix_id
    text :identity_name
    string :identity_name
    text :guid, as: :text_exactm
    time :updated_at, stored: false
    time :created_at, stored: false
    
  end

end
