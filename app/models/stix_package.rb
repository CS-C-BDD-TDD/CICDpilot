class StixPackage < ActiveRecord::Base

  has_many :contributing_sources, primary_key: :stix_id, foreign_key: :stix_package_stix_id, dependent: :destroy
  has_many :stix_markings, primary_key: :guid, as: :remote_object, dependent: :destroy
  accepts_nested_attributes_for :stix_markings, allow_destroy: true
  
  has_many :indicators_packages, primary_key: :stix_id, foreign_key: :stix_package_id, dependent: :destroy
  has_many :indicators, through: :indicators_packages, before_remove: :audit_indicator_removal
  
  has_many :packages_course_of_actions, primary_key: :stix_id, foreign_key: :stix_package_id, dependent: :destroy
  has_many :course_of_actions, through: :packages_course_of_actions, before_remove: :audit_course_of_action_removal

  has_many :exploit_target_packages, primary_key: :stix_id, foreign_key: :stix_package_id, dependent: :destroy
  has_many :exploit_targets, through: :exploit_target_packages, before_remove: :audit_exploit_target_removal

  has_many :ttp_packages, primary_key: :stix_id, foreign_key: :stix_package_id, dependent: :destroy
  has_many :ttps, through: :ttp_packages, before_remove: :audit_ttp_removal

  has_many :ais_statistics, class_name: 'AisStatistic', primary_key: :stix_id, foreign_key: :stix_package_stix_id
  has_many :system_logs, class_name: 'Logging::SystemLog', primary_key: :stix_id, foreign_key: :sanitized_package_id

  belongs_to :created_by_user, class_name: 'User', primary_key: :guid, foreign_key: :created_by_user_guid
  belongs_to :updated_by_user, class_name: 'User', primary_key: :guid, foreign_key: :updated_by_user_guid
  belongs_to :created_by_organization, class_name: 'Organization', primary_key: :guid, foreign_key: :created_by_organization_guid
  belongs_to :updated_by_organization, class_name: 'Organization', primary_key: :guid, foreign_key: :updated_by_organization_guid

  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  has_many :isa_marking_structures, primary_key: :stix_id, through: :stix_markings
  has_many :isa_assertion_structures, primary_key: :stix_id, through: :stix_markings
  has_many :ais_consent_marking_structures, primary_key: :stix_id, through: :stix_markings
  belongs_to :acs_set, primary_key: :guid
  belongs_to :uploaded_file, primary_key: :guid

  before_create :set_created_by_username
  before_save :set_controlled_structures
  before_save :trickledown_feed
  after_save :create_system_badges
  validate :custom_ais

  validates_presence_of :title

  def create_system_badges
    badge_names = self.badge_statuses.collect(&:badge_name)

    if self.uploaded_file_id.present? && badge_names.exclude?("UPLOADED")
      IngestUtilities.create_status_badge(self, "UPLOADED", nil, true)
    end
    
    if self.is_ciscp && badge_names.exclude?("CISCP")
      IngestUtilities.create_status_badge(self, "CISCP", nil, true)
    end

    if self.is_mifr && badge_names.exclude?("MIFR")
      IngestUtilities.create_status_badge(self, "MIFR", nil, true)
    end

    if self.read_only && badge_names.exclude?("READ ONLY")
      IngestUtilities.create_status_badge(self, "READ ONLY", nil, true)
    end

    if self.feeds.present?
      package_feeds = self.feeds.split(",")
      package_feeds.each do |x|
        if badge_names.exclude?(x)
          IngestUtilities.create_status_badge(self, x, nil, true)
        end
      end
    end

  end
  
  # Trickles down the disseminated feed value to all of the associated objects
  def trickledown_feed
    begin
      associations = ["indicators", "course_of_actions", "exploit_targets", "ttps"]
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
    
  # If AIS markings are set in the UI it was requested that ISA ACS markings are set automatically from the AIS conversion rules.
  def custom_ais
    return if self.is_ciscp
    all_markings = self.stix_markings.select {|sm| sm.remote_object_field.blank?}
    ais_struct = all_markings.collect(&:ais_consent_marking_structure).compact.first
    return if all_markings.blank?
    return if ais_struct.blank?  

    if self.submission_mechanism.blank? || self.contributing_sources.blank? || self.contributing_sources.length < 1
      errors.add("A contributing source", "and submission mechanism are required if including AIS Consent markings. \n")
      return false #don't do any more validation until they include a submission mechanism and contributing source
    end

    isa_struct = all_markings.collect(&:isa_marking_structure).compact.first
    isa_asserts = all_markings.collect(&:isa_assertion_structure).compact.first

    # errors.add("ISA Assertions", "must be included with AIS Consent Markings")
    if isa_asserts.blank?
      # If isa asserts are blank when the stix markings save it will run the ais to isa and create the isa markings.
      return
    end

    if isa_struct.blank?
      isa_struct = IsaMarkingStructure.new(
        re_custodian: 'USA.DHS.US-CERT',
        re_originator: 'NONFED',
        data_item_created_at: Time.now
      )

      isa_struct.set_stix_id
      isa_struct.set_guid

      if isa_asserts.stix_marking.present?
        isa_struct.stix_marking = isa_asserts.stix_marking
        isa_asserts.stix_marking.isa_marking_structure = isa_struct
      elsif all_markings.first.respond_to?(:isa_marking_structure)
        isa_struct.stix_marking = all_markings.first
        all_markings.first.isa_marking_structure = isa_struct
      end
    end

    errors.add("Classification", "must be U if including AIS Consent markings") if isa_asserts.cs_classification.blank? || !isa_asserts.cs_classification == 'U'

    if isa_asserts.cs_formal_determination.blank?
      isa_asserts.cs_formal_determination = "INFORMATION-DIRECTLY-RELATED-TO-CYBERSECURITY-THREAT"
    elsif isa_asserts.cs_formal_determination.upcase.exclude?('INFORMATION-DIRECTLY-RELATED-TO-CYBERSECURITY-THREAT')
      isa_asserts.cs_formal_determination << ',INFORMATION-DIRECTLY-RELATED-TO-CYBERSECURITY-THREAT'
    end

    # errors.add("Custodian and originator", "must both be included and custodian must be a USA organization if including AIS Consent Markings\n")
    is_federal = self.contributing_sources.first.is_federal if self.contributing_sources.first.present?
    isa_struct.re_originator = (is_federal.present? && is_federal == true) ? 'USA.USG' : 'NONFED' if isa_struct.re_originator.blank?
    isa_struct.re_custodian = 'USA.DHS.US-CERT' if isa_struct.re_custodian.blank? || !isa_struct.re_custodian.start_with?('USA')

    # errors.add("CISA Proprietary", "must be True if Consent is Everyone")
    if isa_asserts.isa_privs.blank?
      priv = IsaPriv.new(action: 'CISAUSES', scope_is_all: true, effect: 'permit', isa_assertion_structure: isa_asserts)
      isa_asserts.isa_privs << priv
    elsif isa_asserts.isa_privs.select{|x| x.action == "CISAUSES"}.first.respond_to?(:effect) && !(isa_asserts.isa_privs.select{|x| x.action == "CISAUSES"}.first.effect == "permit")
      isa_asserts.isa_privs.select{|x| x.action == "CISAUSES"}.first.effect = "permit"
    end
    
    # errors.add("Formal determination", "must include PUBREL and exclude FOUO if AIS color is white\n")
    if(ais_struct.color == 'white')
      # Set the pubrel fields if not set
      if isa_asserts.public_release == false
        isa_asserts.public_release = true 
        isa_asserts.public_released_by = isa_struct.re_originator if isa_struct.present?
        isa_asserts.public_released_on = Time.now
      end

      # Add the PUBREL fd if not included
      if isa_asserts.cs_formal_determination.upcase.exclude?('PUBREL')
        isa_asserts.cs_formal_determination << ',PUBREL'
      end
        
      if isa_asserts.cs_formal_determination.upcase.include?('FOUO')
        # Then find the index of the FOUO in the cs fd and remove it.  this string is a comma seperated string so account for cases.
        # We don't need to account for the blank FD case the first check was for the idrtct addition.
        index = isa_asserts.cs_formal_determination.upcase.index('FOUO')

        # Account for the case where FOUO is somewhere in the middle of the end
        if isa_asserts.cs_formal_determination[index - 1] == ','
          isa_asserts.cs_formal_determination = isa_asserts.cs_formal_determination.gsub(",FOUO", '')
        # Account for the case where FOUO is in the first position
        elsif isa_asserts.cs_formal_determination[index - 1] != ',' && isa_asserts.cs_formal_determination[index + 1] == ','
          isa_asserts.cs_formal_determination = isa_asserts.cs_formal_determination.gsub("FOUO,", '')
        end
      end
    # errors.add("Formal determination", "must include FOUO and exclude PUBREL if AIS color is amber\n")
    elsif (ais_struct.color == 'amber')
      if isa_asserts.cs_formal_determination.upcase.exclude?('FOUO')
        isa_asserts.cs_formal_determination << ',FOUO'
      end

      if isa_asserts.cs_formal_determination.upcase.include?('PUBREL')
        # First set the pubrel fields to false
        isa_asserts.public_release = false
        isa_asserts.public_released_by = nil
        isa_asserts.public_released_on = nil
        # Then find the index of the pubrel in the cs fd and remove it.  this string is a comma seperated string so account for cases.
        # We don't need to account for the blank FD case the first check was for the idrtct addition.
        index = isa_asserts.cs_formal_determination.upcase.index('PUBREL')

        # Account for the case where pubrel is somewhere in the middle of the end
        if isa_asserts.cs_formal_determination[index - 1] == ','
          isa_asserts.cs_formal_determination = isa_asserts.cs_formal_determination.gsub(",PUBREL", '')
        # Account for the case where pubrel is in the first position
        elsif isa_asserts.cs_formal_determination[index - 1] != ',' && isa_asserts.cs_formal_determination[index + 1] == ','
          isa_asserts.cs_formal_determination = isa_asserts.cs_formal_determination.gsub("PUBREL,", '')
        end
      end
    end

  end


  #after_create :ac_create_default_policy      # TEMPORARILY REMOVED

  attr_accessor :uploaded_kill_chains    # Supports STIX Upload process

  after_save :replicate

  accepts_nested_attributes_for :contributing_sources, allow_destroy: true

  include AcsDefault
  include Auditable
  include Guidable
  include Stixable
  include Ingestible
  include Serialized
  include ClassifiedObject
  include Transferable

  CLASSIFICATION_CONTAINER_OF = [:indicators, :ttps, :exploit_targets, :course_of_actions]

  # The parent parameter for a a STIX Package is the User.
  def self.ingest(uploader, obj, parent = nil)
    p = StixPackage.find_by_stix_id(obj.stix_id)
    if p.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_error(uploader, "Stix Package of #{obj.stix_id} already exists.  Select overwrite to add")
      return false
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      if !obj.stix_id.nil?
        p = StixPackage.find_by_stix_id(obj.stix_id + Setting.READ_ONLY_EXT)
      end
    end

    ciscp_cache = false
    mifr_cache = false
    
    if p.present?
      mifr_cache = p.is_mifr
      ciscp_cache = p.is_ciscp
      p.stix_markings.destroy_all
      p.indicators_packages.destroy_all
      p.exploit_target_packages.destroy_all
      p.packages_course_of_actions.destroy_all
      p.ttp_packages.destroy_all
      p.contributing_sources.destroy_all
      p.acs_set_id = nil
    end

    if p.present? && (uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite))
      p.destroy
      p = nil
    end
    
    p ||= StixPackage.new
    HumanReview.adjust(obj, uploader)
    p.description = obj.description
    p.is_reference = obj.is_reference.nil? ? false : obj.is_reference
    p.short_description = obj.short_description
    # If there is no title included, use the package ID
    p.title = obj.title || obj.stix_id
    
    
    if (p.title.include?('MIFR-')) || mifr_cache
      p.is_mifr = true
    end
        
    
    if (uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)) && !obj.stix_id.nil?
      p.stix_id = obj.stix_id + Setting.READ_ONLY_EXT
      if  (defined? obj.guid) 
        p.guid = obj.guid + Setting.READ_ONLY_EXT
      else 
        p.guid = SecureRandom.uuid + Setting.READ_ONLY_EXT
      end
    else 
      p.stix_id = obj.stix_id
      # Restore the previous guid from the overwritten package if it was
      # stored in the id field of Stix::Native::Package by the
      # overwrite_older_packages method of IngestUtilities. The id field is
      # meant to contain the guid not the stix_id.
      p.guid = obj.id if obj.id.present? && obj.id != obj.stix_id
    end
    p.package_intent = obj.package_intent
    p.stix_timestamp = obj.stix_timestamp
    p.info_src_produced_time = obj.info_src_produced_time
    p.produced_time_precision = obj.produced_time_precision
    p.is_ciscp = ciscp_cache || obj.is_ciscp
 
    
    unless parent.nil?
      p.created_by_user_guid = parent.guid
      p.created_by_organization_guid = parent.organization_guid
      p.updated_by_user_guid = parent.guid
      p.updated_by_organization_guid = parent.organization_guid
      p.username = parent.username
    end
    p.read_only = uploader.read_only

    p
  end

  def set_controlled_structures
    if self.stix_markings.present?
      self.stix_markings.each { |sm| set_controlled_structure(sm) }
    end
  end

  def set_controlled_structure(sm)
    if sm.present?
      if sm.remote_object_field == 'party_name'
        # This is an AIS field marking for the PartyName field that should
        # already have its controlled structure set upon ingestion from
        # STIX XML or via the create_isa_from_ais method of the
        # stix_marking model but if it is somehow empty, it must be se set to
        # the standard controlled structure for the AIS PartyName field marking.
        sm.controlled_structure ||= "//*[local-name()=\"Information_Source\"]" +
            "//*[local-name()=\"PartyName\"]//descendant-or-self::node()"
      elsif sm.remote_object_field.nil? &&
          sm.ais_consent_marking_structure.present?
        # This is an AIS package marking for that will already have its
        # controlled structure set upon ingestion from STIX XML. However, if
        # the stix marking was created via the UI or is somehow empty for
        # another reason, it must be set to the standard controlled structure
        # for the AIS package marking.
        sm.controlled_structure ||= '//node() | //@*'
      else
        sm.controlled_structure =
            "//stix:STIX_Package[@id='#{self.stix_id}']/"
        if sm.remote_object_field.present?
          case sm.remote_object_field
            when 'title'
              sm.controlled_structure +=
                  'stix:STIX_Header/stix:Title/'
            when 'description'
              sm.controlled_structure +=
                  'stix:STIX_Header/stix:Description/'
            when 'short_description'
              sm.controlled_structure +=
                  'stix:STIX_Header/stix:Short_Description/'
            when 'package_intent'
              sm.controlled_structure +=
                  'stix:STIX_Header/stix:Package_Intent/'
            else
              sm.controlled_structure = nil
              return
          end
        end
        sm.controlled_structure += 'descendant-or-self::node()'
        sm.controlled_structure += "| #{sm.controlled_structure}/@*"
      end
    end
  end

  def fd_ais?
		return true if self.ais_consent_marking_structures.present?
    if self.isa_assertion_structures.present?
      self.isa_assertion_structures.each { |ias|
        if ias.fd_ais?
          return true
        end
      }
    end
    false
  end

  def update_is_ais_on_indicators
    if self.indicators.present? && (self.isa_assertion_structures.present? || self.ais_consent_marking_structures.present?)
      if self.fd_ais?
        self.indicators.each { |ind|
          ind.update_is_ais(true)
        }
      else
        self.indicators.each { |ind|
          ind.update_is_ais(false)
        }
      end
    end
  end

  def color
    colors = TlpStructure.joins(:stix_marking).
        where(stix_markings: {remote_object_type: self.class.to_s, remote_object_id: self.stix_id}).
        select(:color).collect(&:color)

    colors += AisConsentMarkingStructure.joins(:stix_marking).
        where(stix_markings: {remote_object_type: self.class.to_s, remote_object_id: self.stix_id}).
        select(:color).collect(&:color)

    TlpStructure.most_restrictive(colors)
  end

  def indicator_stix_ids=(stix_ids)
    self.indicator_ids = Indicator.where(stix_id: stix_ids).pluck(:id)
  end
  
  def course_of_action_stix_ids=(stix_ids)
    self.course_of_action_ids = CourseOfAction.where(stix_id: stix_ids).pluck(:id)
  end

  def exploit_target_stix_ids=(stix_ids)
    self.exploit_target_ids = ExploitTarget.where(stix_id: stix_ids).pluck(:id)
  end

  def ttp_stix_ids=(stix_ids)
    self.ttp_ids = Ttp.where(stix_id: stix_ids).pluck(:id)
  end

  def description=(value)
    if User.has_permission(User.current_user,'view_pii_fields')
      write_attribute(:description,value)
    end
  end

  def short_description=(value)
    if User.has_permission(User.current_user,'view_pii_fields')
      write_attribute(:short_description,value)
      write_attribute(:short_description_normalized, nil)
      unless value.nil?
        write_attribute(:short_description_normalized, value[0, 255].downcase)
      end
    end
  end

  def submission_mechanism=(submission_mechanism)
    submission_mechanism = submission_mechanism.join('|') if submission_mechanism.is_a? Array
    write_attribute(:submission_mechanism,submission_mechanism)
  end

  def submission_mechanism
    submech = read_attribute(:submission_mechanism)
    submech.split("|") if submech.present?
  end

  # Returns a list of distinct Kill Chains associated with Indicators in the
  # Package.

  def kill_chains
    lst = []
    indicators.each do |i|
      arr = i.kill_chains
      lst << arr if arr.present?
    end
    if lst.empty?
      lst
    else
      lst.flatten!.uniq
    end
  end

private

  def audit_indicator_removal(item)
    audit = Audit.basic
    audit.message = "Indicator '#{item.title}' removed from package '#{self.title}'"
    audit.audit_type = :indicator_package_unlink
    ind_audit = audit.dup
    ind_audit.item = item
    item.audits << ind_audit
    pkg_audit = audit.dup
    pkg_audit.item = self
    self.audits << pkg_audit
  end
  
  def audit_course_of_action_removal(item)
    audit = Audit.basic
    audit.message = "Package '#{self.title} removed course of action '#{item.title}'"
    audit.audit_type = :stix_package_course_of_action_unlink
    ind_audit = audit.dup
    ind_audit.item = item
    item.audits << ind_audit
    pkg_audit = audit.dup
    pkg_audit.item = self
    self.audits << pkg_audit
  end

  def audit_exploit_target_removal(item)
    audit = Audit.basic
    audit.message = "Exploit Target '#{item.stix_id}' removed from package '#{self.title}'"
    audit.audit_type = :exploit_target_package_unlink
    ind_audit = audit.dup
    ind_audit.item = item
    item.audits << ind_audit
    pkg_audit = audit.dup
    pkg_audit.item = self
    self.audits << pkg_audit
  end

  def audit_ttp_removal(item)
    audit = Audit.basic
    audit.message = "TTP '#{item.stix_id}' removed from package '#{self.title}'"
    audit.audit_type = :ttp_package_unlink
    ind_audit = audit.dup
    ind_audit.item = item
    item.audits << ind_audit
    pkg_audit = audit.dup
    pkg_audit.item = self
    self.audits << pkg_audit
  end

  def title_exact
    self.title
  end

  def short_description_exact
    self.short_description
  end

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    text :title, as: :text_dash_fix
    string :title
    text :title_exact, as: :text_space_in_paren_fix
    text :username
    string :username
    text :short_description, as: :text_dash_fixm
    string :short_description
    text :short_description_exact, as: :text_space_in_paren_fixm
    string :short_description_normalized
    text :stix_id, as: :text_exact
    string :stix_id
    text :guid, as: :text_exactm
    time :updated_at, stored: false
    time :created_at, stored: false
    
  end

  def ac_create_default_policy
    unless self.stix_markings(true).count > 0
      StixPackage.create_default_policy(self)
    end
  end

  def replicate
    return unless self.submission_mechanism.present?
    return unless self.submission_mechanism.first == 'EMAIL' || self.submission_mechanism.first == 'WEBFORM'
    return if self.uploaded_file.present? && self.uploaded_file.original_inputs.transfer.present?

    replications = Replication.where(repl_type:'publish')
    replications.each do |replication|
      Thread.new do
        begin
          DatabasePoolLogging.log_thread_entry(self.class.to_s, __LINE__)
          stream = ActionView::Base.new(ActionController::Base.view_paths).render(partial: 'stix_packages/show.stix.erb', locals: {stix_package: self, current_user: User.current_user})
          replication.send_data(stream,{'Content-type'=>'application/xhtml+xml'})
        rescue Exception => e
          DatabasePoolLogging.log_thread_error(e, self.class.to_s, __LINE__)
        ensure
          unless Setting.DATABASE_POOL_ENSURE_THREAD_CONNECTION_CLEARING == false
            begin
              ActiveRecord::Base.clear_active_connections!
            rescue Exception => e
              DatabasePoolLogging.log_thread_error(e, self.class.to_s,
                                                   __LINE__)
            end
          end
        end
        DatabasePoolLogging.log_thread_exit(self.class.to_s, __LINE__)
      end
    end
  end

  def set_created_by_username
    self.username ||= self.created_by_user.username if self.created_by_user.present?
  end

end
