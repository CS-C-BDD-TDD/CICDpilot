class ContributingSource < ActiveRecord::Base
  include Guidable
  include Serialized
  include Transferable

  belongs_to :stix_package, primary_key: :stix_id, foreign_key: :stix_package_stix_id
  validates_presence_of :organization_names, message: "Invalid AIS XML, Party Name Element can't be blank"
  validates_presence_of :countries, message: "Invalid AIS XML, Country Element can't be blank"
  validates_presence_of :administrative_areas, message: "Invalid AIS XML, Admin Area Element can't be blank"
  validates_presence_of :organization_info, message: "Invalid AIS XML, Org Info - Industry Type attribute can't be blank"

  before_create :audit_record_create
  before_update :audit_record_update
  before_destroy :audit_record_destroy  

  def self.ingest(uploader,object,stix_package=nil)
    if stix_package.nil?
      IngestUtilities.add_warning(uploader, "Skipping parentless Contributing Source")
      return nil
    elsif !uploader.overwrite && !stix_package.new_record?
      IngestUtilities.add_warning(uploader, "Stix Package already exists, skipping Contributing Source")
      return nil
    end

    cs = ContributingSource.new
    if stix_package.nil?
      IngestUtilities.add_warning(uploader, "Skipping parentless Contributing Source")
      return nil
    else
      stix_package.submission_mechanism = object.tools
      cs.stix_package = stix_package
    end

    cs.organization_names = object.organization_names.join('|')
    cs.countries = object.address_countries.join('|')
    cs.administrative_areas = object.address_admin_area.join('|')
    if (cs.organization_info.is_a? Array)
	    cs.organization_info = object.organization_info.join('|')
    else
      cs.organization_info = object.organization_info
    end
    cs.is_federal = object.is_federal
    cs.set_guid
    
    cs
  end

  def organization_names
    org = read_attribute(:organization_names)
    org.split('|') if org.present?
  end

  def organization_info
    org_info = read_attribute(:organization_info)
    org_info.split('|') if org_info.present?
  end  

  def countries
    countries = read_attribute(:countries)
    countries.split('|') if countries.present?
  end

  def administrative_areas
    areas = read_attribute(:administrative_areas)
    areas.split('|') if areas.present?
  end

  def fix_in_original_input(stix_package=nil,original_input=nil)
    stix_package ||= self.stix_package
    return unless stix_package.present?
    return unless stix_package.uploaded_file.present?
    original_input ||= stix_package.uploaded_file.original_inputs.transfer
    return unless original_input.present?
    # Do not update if the file is CISCP.
    return if Stix::Stix111::PackageInfo.is_ciscp?(original_input.raw_content,
                                                   Setting.CISCP_ID_PATTERNS,
                                                   stix_package.title)

    stream = ActionView::Base.new(ActionController::Base.view_paths).render(partial: 'information_source/show.stix.erb', locals: {stix_package: stix_package})
    information_source_xml = Nokogiri::XML.fragment(stream).elements.first

    UploadLogger.debug("[Upload][original xml pre information source change] #{original_input.raw_content}")

    original_xml = original_input.raw_content
    document = Nokogiri::XML(original_xml)
    xpath_exp="//stix:Information_Source"
    nodeset = document.xpath(xpath_exp).first

    if nodeset.present?
      nodeset.replace(information_source_xml)
    else
      xpath_exp="//stix:STIX_Header"
      nodeset = document.xpath(xpath_exp).first
      nodeset << information_source_xml
    end
    begin
      original_input.raw_content = document.to_xml
      original_input.save!
    rescue Exception => e
      ExceptionLogger.debug("exception: #{e}, message: #{e.message}, backtrace: #{e.backtrace}")
      uploaded_file = stix_package.uploaded_file
      uploaded_file.error_messages.create(description: e.message)
    end
    UploadLogger.debug("[Upload][original xml information source change] #{original_input.raw_content}")
  end

  private 
  
  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    text :guid, as: :text_exact
    string :guid
    string :stix_package_stix_id
    text :organization_names
    text :countries
    text :administrative_areas
    text :organization_info
  end


  def audit_record_create
    return if self.stix_package.blank?
    audit = Audit.basic
    audit.message = "Contributing Source added to package #{stix_package.title}"
    audit.details = Auditable.sanitize_changes(self.attributes, self.class)
    return if audit.blank?
    audit.audit_type = :contributing_source_create
    audit.item = self.stix_package
    audit.user = User.current_user
    self.stix_package.audits << audit
  end

  def audit_record_update
    return if self.stix_package.blank?
    audit = Audit.basic
    audit.message = "Contributing Source modified for package #{stix_package.title}"
    audit.details = Auditable.sanitize_changes(self.changes, self.class)
    return if audit.blank?
    audit.audit_type = :contributing_source_update
    audit.item = self.stix_package
    audit.user = User.current_user
    self.stix_package.audits << audit
  end

  def audit_record_destroy
    return if self.stix_package.blank?    
    audit = Audit.basic
    audit.message = "Contributing source removed from package #{stix_package.title}"
    audit.details =  Auditable.sanitize_changes(self.attributes, self.class)
    return if audit.blank?
    audit.audit_type = :contributing_source_remove
    audit.item = self.stix_package
    audit.user = User.current_user
    self.stix_package.audits << audit
  end

end
