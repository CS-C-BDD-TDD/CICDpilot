class IndicatorsPackage < ActiveRecord::Base

  self.table_name = 'stix_indicators_packages'
  belongs_to :indicator, primary_key: :stix_id, foreign_key: :stix_indicator_id, touch: true
  belongs_to :stix_package, primary_key: :stix_id, foreign_key: :stix_package_id, touch: true

  alias_attribute :obj, :indicator
  alias_attribute :parent, :stix_package

  include Guidable
  include Ingestible
  include LinkingTableCommon
  include Transferable

  attr_reader :is_upload

  def self.ingest(uploader, ind, parent = nil)
    x = IndicatorsPackage.new
    x.stix_indicator_id = ind.stix_id
    x.stix_package_id = parent.stix_id unless parent.nil?
    x
  end

  def is_upload
	  if @is_upload.nil?
		  false
	  else
		  @is_upload
	  end
  end

  def audit_ip_save
    if (self.indicator.present? &&
        self.stix_package.present?)
      audit = Audit.basic
      audit.message = "Indicator '#{self.indicator.title}' added to package '#{self.stix_package.title}'"
      audit.audit_type = :indicator_package_link
      ind_audit = audit.dup
      ind_audit.item = self.indicator
      self.indicator.audits << ind_audit
      pkg_audit = audit.dup
      pkg_audit.item = self.stix_package
      self.stix_package.audits << pkg_audit
      return
    end
  end
end
