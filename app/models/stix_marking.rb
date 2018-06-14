class StixMarking < ActiveRecord::Base
  VALID_CLASSES = %w(
                    Indicator
                    StixPackage
                    HttpSession
                    FileHash
                    EmailMessage
                    Domain
                    Hostname
                    Port
                    DnsRecord
                    CyboxMutex
                    CyboxFile
                    Address
                    Uri
                    Registry
                    Observable
                    NetworkConnection
                    Link
                    FileHash
                    RegistryValue
                    ThreatActor
                    CourseOfAction
                    ExploitTarget
                    Vulnerability
                    Ttp
                    AttackPattern
                    SocketAddress
                    DnsQuery
                )
  SPECIAL_CLASSES = %w(
                    FileHash
                )

  belongs_to :remote_object,
           primary_key: :guid,
           foreign_key: :remote_object_id,
           foreign_type: :remote_object_type,
           polymorphic: true

  has_one :isa_marking_structure,class_name: 'IsaMarkingStructure', primary_key: :stix_id, foreign_key: :stix_marking_id, dependent: :destroy
  has_one :isa_assertion_structure,class_name: 'IsaAssertionStructure', primary_key: :stix_id, foreign_key: :stix_marking_id, dependent: :destroy
  has_one :simple_marking_structure,class_name: 'SimpleStructure', primary_key: :stix_id, foreign_key: :stix_marking_id, dependent: :destroy
  has_one :tlp_marking_structure,class_name: 'TlpStructure',primary_key: :stix_id, foreign_key: :stix_marking_id, dependent: :destroy
  has_one :ais_consent_marking_structure,class_name: 'AisConsentMarkingStructure',primary_key: :stix_id, foreign_key: :stix_marking_id, dependent: :destroy

  accepts_nested_attributes_for :isa_marking_structure
  accepts_nested_attributes_for :isa_assertion_structure, allow_destroy: true
  accepts_nested_attributes_for :simple_marking_structure
  accepts_nested_attributes_for :ais_consent_marking_structure, allow_destroy: true
  accepts_nested_attributes_for :tlp_marking_structure, allow_destroy: true, reject_if: proc {|attributes| attributes['color'].blank?}

  before_create :audit_record_create
  before_update :audit_record_update
  before_destroy :audit_record_destroy
  before_destroy :unset_pm_cache_value
  before_save :set_controlled_structure
  before_save :set_pm_cache_value
  before_save :set_special_pm_cache
  after_create :create_isa_from_ais

  validate :field_level_markings

  include Auditable
  include Guidable
  include Stixable
  include Ingestible
  include Serialized
  include Transferable

  def self.ingest(uploader, obj, parent = nil)
    if parent.nil?
      IngestUtilities.add_warning(uploader, "Skipping parentless STIX marking")
      return nil
    end

    m = StixMarking.new
    HumanReview.adjust(obj, uploader)
    m.controlled_structure = obj.controlled_structure
    m.is_reference = obj.is_reference
    m.is_reference = false if m.is_reference.nil?
    if parent.guid.blank?
      parent.set_guid if parent.respond_to?(:set_guid)
    end
    m.remote_object_id = parent.guid
    m.remote_object_type = parent.class.to_s
    m.remote_object_field = (defined? obj.remote_object_field) ? obj.remote_object_field : nil
    m.remote_object_field = nil if m.remote_object_field == 'party_name' &&
        m.remote_object_type == 'StixPackage'
    m.remote_object = parent
    parent.association(:stix_markings).add_to_target(m)

    m.set_guid
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      m.stix_id = obj.stix_id ? obj.stix_id + Setting.READ_ONLY_EXT : obj.stix_id
      m.guid = m.guid ? m.guid + Setting.READ_ONLY_EXT : m.guid
      if m.stix_id.nil?
        m.set_stix_id
        if !m.stix_id.include?(Setting.READ_ONLY_EXT)
          m.stix_id = m.stix_id + Setting.READ_ONLY_EXT
        end
      end
    else
      m.stix_id = obj.stix_id
    end

    new_ms = nil

    obj.marking_structures.each do |ms|
      case ms.class.name
        when 'Stix::Native::IsaMarkingAssertion'
             new_ms = IsaAssertionStructure.ingest(uploader, m, ms)
             m.isa_assertion_structure = new_ms unless new_ms.nil?
        when 'Stix::Native::IsaMarkingStructure'
             new_ms = IsaMarkingStructure.ingest(uploader, m, ms)
             m.isa_marking_structure = new_ms unless new_ms.nil?
        when 'Stix::Native::MarkingStructure'
             IngestUtilities.add_warning(uploader, "Skipping marking structure idref")
        when 'Stix::Native::SimpleMarkingStructure'
             new_ms = SimpleStructure.ingest(uploader, m, ms)
             m.simple_marking_structure = new_ms unless new_ms.nil?
        when 'Stix::Native::TlpMarkingStructure'
             new_ms = TlpStructure.ingest(uploader, m, ms)
             m.tlp_marking_structure = new_ms unless new_ms.nil?
        when 'Stix::Native::AisConsentMarkingStructure'
             new_ms = AisConsentMarkingStructure.ingest(uploader, m, ms)
             m.ais_consent_marking_structure = new_ms unless new_ms.nil?
      end
    end

    m     # Return the unsaved data marking and its children
  end

  # Gets a non-homogenous array of all the Marking Structures associated with
  # this Marking.
  def structures
    [self.tlp_marking_structure,self.simple_marking_structure,self.isa_marking_structure,self.isa_assertion_structure,self.ais_consent_marking_structure].compact
  end

  private

    searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
      text :guid, as: :text_exact
      text :remote_object_id
      text :remote_object_type
      text :stix_id
      time :created_at, stored: false
      time :updated_at, stored: false
      text :remote_object_field
      text :controlled_structure, as: :text_uax

    end
    
    def audit_name
      if remote_object.respond_to?(:title) && remote_object.title.present?
        remote_object.title
      elsif remote_object.respond_to?(:stix_id) && remote_object.stix_id.present?
        remote_object.stix_id
      elsif remote_object.respond_to?(:cybox_object_id) && remote_object.cybox_object_id.present?
        remote_object.cybox_object_id
      else
        remote_object.class.to_s
      end
    end

    def audit_record_create
      return if self.remote_object.blank?
      audit = Audit.basic
      audit.message = "STIX Marking Structure added to #{audit_name}"
      audit = compile_subitem_audit_changes(audit)
      return if audit.blank?
      audit.audit_type = :marking_create
      audit.item = self.remote_object
      audit.user = User.current_user
      self.remote_object.audits << audit
    end

    def audit_record_update
      return if self.remote_object.blank?
      audit = Audit.basic
      audit.message = "STIX Marking Structure modified on #{audit_name}"
      audit = compile_subitem_audit_changes(audit)
      return if audit.blank?
      audit.audit_type = :marking_update
      audit.item = self.remote_object
      audit.user = User.current_user
      self.remote_object.audits << audit
    end

    def audit_record_destroy
      return if self.remote_object.blank?
      audit = Audit.basic
      audit.message = "STIX Marking Structure removed from #{audit_name}"
      audit = compile_subitem_audit_changes(audit, true)
      return if audit.blank?
      audit.audit_type = :marking_destroy
      audit.item = self.remote_object
      audit.user = User.current_user
      self.remote_object.audits << audit
    end

    def extract_stix_ids(arr, stype)
      ids = []
      arr.each {|x| ids << x.stix_structure_id if x.stix_structure_type == stype}
      ids
    end

  def set_controlled_structure
    unless self.controlled_structure.present?
      if self.remote_object.present? &&
          self.remote_object.respond_to?(:set_controlled_structure)
        self.remote_object.set_controlled_structure(self)
      elsif self.remote_object.present? &&
          self.remote_object.respond_to?(:cybox_object_id)
        self.controlled_structure =
            "//cybox:Object[@id='#{self.remote_object.cybox_object_id}']/" +
                'descendant-or-self::node()'
        self.controlled_structure += "| #{self.controlled_structure}/@*"
      elsif self.remote_object_type == 'StixPackage'
        self.controlled_structure = '//node()'
      else
        self.stix_id = SecureRandom.stix_id(self) unless self.stix_id.present?
        self.controlled_structure =
            "//*[@id=\"#{self.stix_id}\"]//descendant-or-self::node()"
      end
    end
  end

  def unset_pm_cache_value
    return unless self.remote_object.present? && VALID_CLASSES.include?(self.remote_object_type)
    klass = self.remote_object.class
    return unless klass.column_names.include?(self.remote_object_field)

    if klass.column_names.include?(self.remote_object_field + '_c')
      pm_column = self.remote_object_field + '_c'
      hsh = {}
      hsh[pm_column.to_sym] = nil
      self.remote_object.update_columns(hsh)
    end
  end

  def set_pm_cache_value
    return unless self.isa_assertion_structure.present? && VALID_CLASSES.include?(self.remote_object_type)
    klass = self.remote_object.class
    return if klass.blank? || !klass.respond_to?(:column_names)
    return unless klass.column_names.include?(self.remote_object_field)

    if klass.column_names.include?(self.remote_object_field + '_c')
      pm_column = self.remote_object_field + '_c'
      classification = self.isa_assertion_structure.cs_classification
      if self.isa_assertion_structure.public_release == true && classification.downcase != 'u'
        classification = 'U'
      end
      hsh = {}
      hsh[pm_column.to_sym] = classification
      self.remote_object.update_columns(hsh)
    end
  end

  def set_special_pm_cache
    return unless self.isa_assertion_structure.present? && SPECIAL_CLASSES.include?(self.remote_object_type)
    klass = self.remote_object.class

    if klass == FileHash
      if self.remote_object.simple_hash_value.present?
        pm_column =  'simple_hash_value_normalized_c'
      else
        pm_column =  'fuzzy_hash_value_normalized_c'
      end
    end

    classification = self.isa_assertion_structure.cs_classification
    hsh = {}
    hsh[pm_column.to_sym] = classification
    self.remote_object.update_columns(hsh)
  end

  def compile_subitem_audit_changes(audit, destroy=false)
    # if we are destroying we still want to edit what is being destroyed, but self.destroyed? is false so we cant use that.
    if destroy
      sanitized_changes = Auditable.sanitize_changes(self.attributes, self.class)
      sanitized_changes.merge!({'isa_marking_structure'=> Auditable.sanitize_changes(self.isa_marking_structure.attributes, self.isa_marking_structure.class)}) if self.isa_marking_structure.present? && self.isa_marking_structure.attributes.present?
      if self.isa_assertion_structure.present?
        if self.isa_assertion_structure.attributes.present?
          sanitized_changes.merge!({'isa_assertion_structure'=> Auditable.sanitize_changes(self.isa_assertion_structure.attributes, self.isa_assertion_structure.class)})
        end

        if self.isa_assertion_structure.isa_privs.present?
          isa_privs = {}
          self.isa_assertion_structure.isa_privs.each do |ips|
            isa_privs.merge!({ips.action.to_s => Auditable.sanitize_changes(ips.attributes, ips.class)}) if ips.attributes.present?
          end
          sanitized_changes.merge!({'isa_privs' => isa_privs}) if isa_privs.present?
        end

        if self.isa_assertion_structure.further_sharings.present?
          further_sharings = {}
          self.isa_assertion_structure.further_sharings.each do |fs|
            further_sharings.merge!({fs.scope.to_s => Auditable.sanitize_changes(fs.attributes, fs.class)}) if fs.attributes.present?
          end
          sanitized_changes.merge!({'further_sharings' => further_sharings}) if further_sharings.present?
        end
      end
      sanitized_changes.merge!({'tlp_marking_structure'=> Auditable.sanitize_changes(self.tlp_marking_structure.attributes, self.tlp_marking_structure.class)}) if self.tlp_marking_structure.present? && self.tlp_marking_structure.attributes.present?
      sanitized_changes.merge!({'simple_marking_structure'=> Auditable.sanitize_changes(self.simple_marking_structure.attributes, self.simple_marking_structure.class)}) if self.simple_marking_structure.present? && self.simple_marking_structure.attributes.present?
      sanitized_changes.merge!({'ais_consent_marking_structure'=> Auditable.sanitize_changes(self.ais_consent_marking_structure.changes, self.ais_consent_marking_structure.class)}) if self.ais_consent_marking_structure.present? && self.ais_consent_marking_structure.changes.present?

      audit.details = sanitized_changes
    else
    # Otherwise just audit what we normally audit.
      sanitized_changes = Auditable.sanitize_changes(self.changes, self.class)
      sanitized_changes.merge!({'isa_marking_structure'=> Auditable.sanitize_changes(self.isa_marking_structure.changes, self.isa_marking_structure.class)}) if self.isa_marking_structure.present? && self.isa_marking_structure.changes.present?
      if self.isa_assertion_structure.present?
        if self.isa_assertion_structure.changes.present?
          sanitized_changes.merge!({'isa_assertion_structure'=> Auditable.sanitize_changes(self.isa_assertion_structure.changes, self.isa_assertion_structure.class)})
        end

        if self.isa_assertion_structure.isa_privs.present?
          isa_privs = {}
          self.isa_assertion_structure.isa_privs.each do |ips|
            isa_privs.merge!({ips.action.to_s => Auditable.sanitize_changes(ips.changes, ips.class)}) if ips.changes.present?
          end
          sanitized_changes.merge!({'isa_privs' => isa_privs}) if isa_privs.present?
        end

        if self.isa_assertion_structure.further_sharings.present?
          further_sharings = {}
          self.isa_assertion_structure.further_sharings.each do |fs|
            further_sharings.merge!({fs.scope.to_s => Auditable.sanitize_changes(fs.changes, fs.class)}) if fs.changes.present?
          end
          sanitized_changes.merge!({'further_sharings' => further_sharings}) if further_sharings.present?
        end
      end

      sanitized_changes.merge!({'tlp_marking_structure'=> Auditable.sanitize_changes(self.tlp_marking_structure.changes, self.tlp_marking_structure.class)}) if self.tlp_marking_structure.present? && self.tlp_marking_structure.changes.present?
      sanitized_changes.merge!({'simple_marking_structure'=> Auditable.sanitize_changes(self.simple_marking_structure.changes, self.simple_marking_structure.class)}) if self.simple_marking_structure.present? && self.simple_marking_structure.changes.present?
      sanitized_changes.merge!({'ais_consent_marking_structure'=> Auditable.sanitize_changes(self.ais_consent_marking_structure.changes, self.ais_consent_marking_structure.class)}) if self.ais_consent_marking_structure.present? && self.ais_consent_marking_structure.changes.present?

      return nil if sanitized_changes.blank?

      audit.details = sanitized_changes.hmap do |k,v|
        if v.is_a? Array
          {k=>v[1]}
        elsif v.is_a? Hash
          {k=>v.hmap {|k,v|
            if v.is_a? Array
              {k=>v[1]}
            elsif v.is_a? Hash
              {k=>v.hmap {|k,v|{k=>v[1]}}}
            end
            }
          }
        end
      end.to_s
    end

    # Add in the remote object field so you can always see it.
    audit.details = "{\"remote_object_field\" => \"#{self.remote_object_field}\"}" + audit.details

    audit
  end

  # Add the comment node setting SOURCE to OTHER to the Nokogiri XML
  # Document if a comment node with the SOURCE does not already exist.
  def set_source_to_other(xml_doc)
    source_xpath_exp = "//stix:STIX_Package//comment()[contains(.,'SOURCE')]"
    # Return unless there is no SOURCE comment node.
    return unless xml_doc.xpath(source_xpath_exp).empty?

    xpath_exp='//stix:STIX_Package'
    nodeset = xml_doc.xpath(xpath_exp).first
    comment = Nokogiri::XML::Comment.new(xml_doc, ' SOURCE: OTHER ')
    nodeset.prepend_child(comment)
    xml_doc
  end

  def field_level_markings
    return unless self.remote_object_field.present?

    if VALID_CLASSES.include?(self.remote_object_type)
      klass = self.remote_object_type
      begin
        klass = self.remote_object_type.constantize
      rescue Exception => e
        errors.add(:base, "#{self.remote_object_type} is not a valid object to apply a stix marking to")
        return
      end

      errors.add(:base,"Invalid field for #{self.remote_object_type}") unless klass.column_names.include?(self.remote_object_field)
    end
  end

  public

  def fd_ais?
		return true if self.ais_consent_marking_structure.present?
    return false if self.isa_assertion_structure.blank?
    return self.isa_assertion_structure.fd_ais?
  end

  def create_isa_from_ais(remote_object = nil,original_input=nil)
    return unless self.ais_consent_marking_structure.present? && self.isa_assertion_structure.blank? #Check if marking already had ISA
    return if self.remote_object.blank? && remote_object.blank? #Check if remote object present or passed in as argument
    return if self.remote_object_field.present?
    return if self.remote_object.acs_set.present?
    return if self.remote_object.respond_to?(:is_ciscp) && self.remote_object.is_ciscp == true

    #Check if previously made Marking already had ISA
    self.remote_object.stix_markings.where.not(stix_id: self.stix_id).each do |sm|
      return if sm.isa_assertion_structure.present? ||
          sm.isa_marking_structure.present? || sm.remote_object_field.present?
    end if self.remote_object.present?

    consent = self.ais_consent_marking_structure.consent.downcase
    color = self.ais_consent_marking_structure.color.downcase

    marking = IsaMarkingStructure.new(
        stix_marking: self,
        re_custodian: 'USA.DHS.US-CERT',
        data_item_created_at: Time.now
    )

    is_federal = self.remote_object.contributing_sources.first.is_federal if self.remote_object.contributing_sources.present?
    marking.re_originator = is_federal ? 'USA.USG' : 'NONFED'

    assertion = IsaAssertionStructure.new(stix_marking: self, privilege_default: 'deny', is_default_marking: true)

    assertion.cs_info_caveat = 'POSSIBLEPII'
    assertion.cs_info_caveat += ',CISAPROPRIETARY' if self.ais_consent_marking_structure.proprietary
    priv = IsaPriv.new(action: 'CISAUSES', scope_is_all: true, effect: 'permit', isa_assertion_structure: assertion)
    assertion.isa_privs << priv

    # Field level markings.
    is_fl_marking_needed = false # We may not ultimately need a field-level
    # marking based on TLP and consent values. It will only be saved if this
    # is set to true below.
    fl_controlled_structure = "//*[local-name()=\"Information_Source\"]" +
        "//*[local-name()=\"PartyName\"]//descendant-or-self::node()"
    fl_stix_marking = StixMarking.new(controlled_structure: fl_controlled_structure)
    fl_stix_marking.remote_object = self.remote_object if self.remote_object
                                                              .present?
    fl_isa_marking = IsaMarkingStructure.new(
        stix_marking: fl_stix_marking,
        re_custodian: 'USA.DHS.US-CERT',
        data_item_created_at: Time.now
    )

    fl_isa_marking.re_originator = is_federal ? 'USA.USG' : 'NONFED'

    fl_assertion = IsaAssertionStructure.new(stix_marking: fl_stix_marking, privilege_default: 'deny')

    fl_assertion.cs_info_caveat = 'POSSIBLEPII'
    fl_assertion.cs_info_caveat += ',CISAPROPRIETARY' if self.ais_consent_marking_structure.proprietary
    fl_priv = IsaPriv.new(action: 'CISAUSES', scope_is_all: true, effect: 'permit', isa_assertion_structure: fl_assertion)
    fl_assertion.isa_privs << fl_priv

    case color
      when 'white'
        assertion.cs_formal_determination = 'PUBREL'
        assertion.sharing_default = 'permit'
        assertion.public_release = true
        assertion.public_released_by = marking.re_originator
        assertion.public_released_on = Time.now
        if consent == 'usg'
          # Field level markings.
          fl_assertion.cs_orgs = 'USA.USG'
          fl_assertion.sharing_default = 'deny'
          fl_assertion.further_sharings << FurtherSharing.new(scope: 'USA.USG', effect: 'permit', isa_assertion_structure: fl_assertion)
          is_fl_marking_needed = true
        end
      when 'green'
        assertion.cs_orgs = 'USA.USG'
        assertion.sharing_default = 'deny'
        assertion.further_sharings << FurtherSharing.new(scope: 'FOREIGNGOV', effect: 'permit', isa_assertion_structure: assertion)
        assertion.further_sharings << FurtherSharing.new(scope: 'SECTOR', effect: 'permit', isa_assertion_structure: assertion)
        assertion.further_sharings << FurtherSharing.new(scope: 'USA.USG', effect: 'permit', isa_assertion_structure: assertion)
        if consent == 'usg'
          # Field level markings.
          fl_assertion.cs_orgs = 'USA.USG'
          fl_assertion.sharing_default = 'deny'
          fl_assertion.further_sharings << FurtherSharing.new(scope: 'USA.USG', effect: 'permit', isa_assertion_structure: fl_assertion)
          is_fl_marking_needed = true
        end
      when 'amber'
        assertion.cs_orgs = 'USA.USG'
        assertion.sharing_default = 'deny'
        assertion.further_sharings << FurtherSharing.new(scope: 'USA.USG', effect: 'permit', isa_assertion_structure: assertion)
    end

    tlp = TlpStructure.new(color: color, stix_marking: self)

    self.isa_marking_structure = marking
    self.isa_assertion_structure = assertion
    self.tlp_marking_structure = tlp

    assertion.set_stix_id
    assertion.set_guid
    marking.set_stix_id
    marking.set_guid

    if is_fl_marking_needed
      # Field level markings.
      fl_stix_marking.isa_marking_structure = fl_isa_marking
      fl_stix_marking.isa_assertion_structure = fl_assertion

      fl_assertion.set_stix_id
      fl_assertion.set_guid
      fl_isa_marking.set_stix_id
      fl_isa_marking.set_guid
      fl_stix_marking.set_stix_id
      fl_stix_marking.set_guid
    end

    if (self.remote_object.present? && self.remote_object.respond_to?(:uploaded_file) && self.remote_object.uploaded_file.present?) || original_input.present?
      original_input ||= self.remote_object.uploaded_file.original_inputs.transfer
      UploadLogger.debug("[Upload][original xml pre handling change] #{original_input.raw_content}")
      if original_input.present?
        original_xml = original_input.raw_content

        document = Nokogiri::XML(original_xml)
        namespaces = Stix::Stix111::Definitions::NAMESPACES.select {|x| x[:ns] == :isa || x[:ns] == :edh2 || x[:ns] == :edh2cyberMarkingAssert || x[:ns] == :edh2cyberMarking}
        namespaces.each do |namespace|
          unless document.namespaces.keys.include?("xmlns:"+namespace[:ns].to_s)
            document.root.add_namespace(namespace[:ns].to_s,namespace[:alias])
            schema_location = document.root.attributes['schemaLocation']
            unless namespace[:ns] == :isa || schema_location.blank?
              document.root.attributes['schemaLocation'].value = document.root.attributes['schemaLocation'].value + " #{namespace[:alias]} #{namespace[:xsd]}"
            end
          end
        end
        xpath_exp="//*[local-name()='Handling']"
        nodeset = document.xpath(xpath_exp).first
        top_level_ns =
            nodeset.namespace.present? ? nodeset.namespace.prefix.gsub(/xmlns:/, '') : 'stix'
        locals_stix_markings = [self]
        # Add field-level marking if necessary.
        locals_stix_markings << fl_stix_marking if is_fl_marking_needed
        av = ActionView::Base.new(ActionController::Base.view_paths)
        av.class_eval do
	        include IndicatorHelper
        end
        stream = av.render(partial: 'stix_markings/show.stix.erb', locals: {stix_markings: locals_stix_markings, top_level_name_space: top_level_ns})
        frag = Nokogiri::XML.fragment(stream).elements.first
        nodeset.replace(frag)

        # Add the comment node setting SOURCE to OTHER if a comment node with
        # the SOURCE does not already exist.
        set_source_to_other(document)

        original_input.raw_content = document.to_xml
        original_input.save
        
      end
    end

    if !self.new_record?
      begin
        assertion.save!
        assertion.isa_privs.each(&:save!)
        assertion.further_sharings.each(&:save!)
        marking.save!
        tlp.save!
        if is_fl_marking_needed
          # Field level markings.
          fl_assertion.save!
          fl_assertion.isa_privs.each(&:save!)
          fl_assertion.further_sharings.each(&:save!)
          fl_isa_marking.save!
          fl_stix_marking.save!
        end
      rescue Exception => e
        IngestUtilities.add_error(self.remote_object.uploaded_file, "#{e.backtrace.first}: #{e.message} (#{e.class})")
        ExceptionLogger.debug("exception: #{e}, message: #{e.message}, backtrace: #{e.backtrace}")
      end
    end
  end

end
