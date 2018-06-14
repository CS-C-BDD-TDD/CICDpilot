class IndicatorsThreatActor < ActiveRecord::Base

  self.table_name = 'indicators_threat_actors'
  belongs_to :indicator, primary_key: :stix_id, foreign_key: :stix_indicator_id, touch: true
  belongs_to :threat_actor, primary_key: :stix_id, foreign_key: :threat_actor_id, touch: true
  belongs_to :user, foreign_key: :user_guid, primary_key: :guid

  alias_attribute :obj, :indicator
  alias_attribute :parent, :threat_actor

  include Guidable
  include Ingestible
  include LinkingTableCommon
  include Transferable

  attr_reader :is_upload

  def self.ingest(uploader, ind, parent = nil)
    x = IndicatorsThreatActor.new
    x.stix_indicator_id = ind.stix_id
    x.threat_actor_id = parent.stix_id unless parent.nil?
    x
  end

  def is_upload
    if @is_upload.nil?
      false
    else
      @is_upload
    end
  end

  def audit_it_save
    if (self.indicator.present? &&
        self.threat_actor.present?)
      audit = Audit.basic
      audit.message = "Indicator '#{self.indicator.title}' added to threat actor '#{self.threat_actor.title}'"
      audit.audit_type = :indicator_threat_actor_link
      ind_audit = audit.dup
      ind_audit.item = self.indicator
      self.indicator.audits << ind_audit
      pkg_audit = audit.dup
      pkg_audit.item = self.threat_actor
      self.threat_actor.audits << pkg_audit
      return
    end
  end
  
  private
    after_commit :set_threat_actor_value_on_indicator
    
    def set_threat_actor_value_on_indicator
      self.indicator.set_threat_actor_value
    end

end
