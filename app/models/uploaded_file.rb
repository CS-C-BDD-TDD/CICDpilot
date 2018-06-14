require 'stix'

class UploadedFile < ActiveRecord::Base
  include Guidable
  include Stix::Utilities
  include Ingestible
  include Serialized
  include Transferable
  
  # Convenient scopes to list the different types of uploads

  scope :attachments, -> { joins(:original_inputs).where("original_input.input_category = 'Attachment'") }
  scope :stix_uploads, -> { joins("LEFT JOIN original_input on original_input.uploaded_file_id = uploaded_files.guid").where("uploaded_files.status = ? or original_input.input_category = 'Upload' and (original_input.input_sub_category != ? OR original_input.input_sub_category is null)", "C", OriginalInput::XML_SANITIZED).includes(:error_messages, :warnings)}
  scope :weather_map_uploads, -> { joins(:original_inputs).where("original_input.input_category = 'WeatherMap Image'") }

  has_many   :error_messages, -> { where(:is_warning => false) }, :as => :source, primary_key: :guid
  has_many   :warnings, -> { where(:is_warning => true) }, :as => :source, primary_key: :guid, :class_name => ErrorMessage

  has_many :original_inputs, primary_key: :guid
  has_one  :human_review
  has_many :stix_packages, primary_key: :guid, foreign_key: :uploaded_file_id
  has_many :ais_statistics, foreign_key: :uploaded_file_id
  belongs_to  :user, foreign_key: :user_guid, primary_key: :guid
  belongs_to  :avp_message, foreign_key: :avp_message_id, primary_key: :id

  has_many :indicator_zip
  has_many :indicators, through: :indicator_zip

  # Default file name, used when one is not provided, e.g. - loading via API.
  DEFAULT_STIX_FILE_NAME = 'API STIX Upload'

  # Failed File Redaction Name
  FAILED_FILE_NAME = '<File Name Redacted>'

  # The list of accepted file types for uploads.

  # if we want to change to mime type
  # application/msword
  # application/vnd.openxmlformats-officedocument.wordprocessingml.document
  # application/vnd.ms-excel
  # application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  # image/jpeg
  # image/png
  # text/xml
  # application/pdf
  ATTACHMENTS_ACCEPTED_FILE_TYPES = 
  %w(
    .doc
    .docx
    .xls
    .xlsx
    .jpg
    .png
    .xml
    .pdf
  )
  # apparently zip can be different types?
  # zip can also be multipart/x-zip, application/x-compressed, application/x-zip, application/x-zip-compressed?
  # zip file also can be application/octet-stream but it seems it applies to more than just zip files

  # zip files mime types
  # application/zip
  # application/x-zip
  # application/x-zip-compressed
  # multipart/x-zip
  BULK_UPLOAD_ACCEPTED_FILE_TYPES = 
  %w(
    .zip
  )
  
  # xml files mime types
  # text/xml
  UPLOAD_ACCEPTED_FILE_TYPES = 
  %w(
    .xml
  )

  # END FILE TYPES

  default_scope { order(:created_at => :desc) }

  # Internal bookkeeping data items-------------------------------------------
  attr_reader :incoming_objects  # Native objects; initially unsaved.
  attr_reader :input_category    # Type: Attachment, Upload, WeatherMap Image
  attr_reader :is_file_upload    # Flag: TRUE for file upload, FALSE for API.
  attr_reader :mime_type         # The type of file being uploaded.
  @file_path = nil               # Full path of uploaded file
  attr_accessor :replicate

  validates_presence_of     :file_name
  validates_length_of       :file_name, :minimum => 5
  validates_presence_of     :status
  validates_inclusion_of    :status, :in => %w(S F I C N R)
  validates_presence_of     :user_guid

  def set_portion_marking
    return unless self.respond_to?(:portion_marking)

    highest_classification = ''
    value = -1

    if !self.stix_packages.blank?
      self.stix_packages.each do |e|
        if !e.portion_marking.nil? && Classification::CLASSIFICATIONS.index(e.portion_marking) > value
          value = Classification::CLASSIFICATIONS.index(e.portion_marking)
          highest_classification = e.portion_marking
        end
      end
    elsif !self.indicators.blank?
      self.indicators.each do |e|
        if !e.portion_marking.nil? && Classification::CLASSIFICATIONS.index(e.portion_marking) > value
          value = Classification::CLASSIFICATIONS.index(e.portion_marking)
          highest_classification = e.portion_marking
        end
      end
    end

    if value > -1 && highest_classification != nil
      self.portion_marking = highest_classification
    end
  end

  def replicate=(replicate)
    if replicate.is_a? String
      @replicate = false if replicate.downcase == 'n' || replicate == '0'
      @replicate = true  if replicate.downcase == 'y' || replicate == '1'
    elsif replicate.is_a?(TrueClass) || replicate.is_a?(FalseClass)
      @replicate = replicate
    elsif replicate.is_a? NilClass
      @replicate = true
    end
  end

  # Upload a file as an attachment, which will be stored in the ORIGINAL_INPUT
  # table. Attachments are currently only associated with Indicators.

  def upload_attachment(upload, current_user_guid, stix_id, references = {}, options = {})
    self.init_uploaded_file(upload, 'Attachment', current_user_guid, options)
    XmlSaving.store_original_file(@file_path, self.guid, @input_category, @mime_type, stix_id, 'Indicator')

    # Set the reference attributes that were set by the user in the UI if set.
    self.reference_title = references[:ref_title]
    self.reference_number = references[:ref_num]
    self.reference_link = references[:ref_link]
    
    # Save the attribute that it was an attachment
    self.is_attachment = true
    
    self.status = ActionStatus::SUCCEEDED
    self.save
    first_oi = self.original_inputs.active.first

    indicator=first_oi.indicator
    audit = Audit.basic
    audit.message = "File #{self.file_name} attached."

    # add the reference info into the audits if existant.
    audit.message += "\nReference Title: #{self.reference_title}, added." unless self.reference_title.nil? || self.reference_title.blank?
    audit.message += "\nReference Number: #{self.reference_number}, added." unless self.reference_number.nil? || self.reference_number.blank?
    audit.message += "\nReference Link: #{self.reference_link}, added." unless self.reference_link.nil? || self.reference_link.blank?

    audit.item = indicator
    audit.audit_type = :attachment
    indicator.audits << audit
    indicator.updated_at = Time.now
    indicator.save
    IngestUtilities.cleanup(self, @file_path)
  rescue StandardError => e
    IngestUtilities.add_error(self, "#{e.backtrace.first}: #{e.message} (#{e.class})")
    ExceptionLogger.debug("exception: #{e}, message: #{e.message}, backtrace: #{e.backtrace}")
    self.save
    IngestUtilities.cleanup(self, @file_path)
  end

  # Upload a data file (or an XML string), and then parse and load the data.
  # STIX is the only data format accepted. Currently supported options include:
  #
  #    :human_review_approved  If TRUE, then an XML file with Human Review
  #                     markings will be fully ingested rather than loaded
  #                     for Human Review.
  #
  #    :overwrite       If TRUE, then overwrite an existing package with the
  #                     content of the current upload.
  #
  #    :validate_only   If TRUE, then parsing will be done, but data will not
  #                     be loaded into the database.

  def upload_data_file(upload, current_user_guid, options = {})
    self.init_uploaded_file(upload, 'Upload', current_user_guid, options)
    stixish = is_file_upload ? is_stix_file?(@file_path) : is_stix?(upload)

    if stixish
      if options[:human_review_approved]
        raw_xml = upload
        IngestUtilities.add_warning(self, "Human Review approved, full ingestion starting at #{Time.now}")
        oi = self.original_inputs.active.first
      else
        if is_file_upload
          oi = XmlSaving.store_original_file(@file_path, self.guid, @input_category, @mime_type)
          source_oi = XmlSaving.store_original_file(@file_path, self.guid, 'SOURCE', @mime_type)
        else
          oi = XmlSaving.store_original_input(upload, self.guid, @input_category, @mime_type)
          source_oi = XmlSaving.store_original_input(upload, self.guid, 'SOURCE', @mime_type)
        end

        # This is not "Sanitization" per se...it's fixing invalid ID's, so it
        # gets run every time
        s = Sanitization.new
        s.sanitize_id_format_raw_xml(oi) unless
            Stix::Stix111::PackageInfo.is_ciscp?(oi.raw_content,
                                                 Setting.CISCP_ID_PATTERNS)                                          
                                                 
        raw_xml = oi.utf8_raw_content
        IngestUtilities.add_warning(self, s.get_warnings, true) if s.get_warnings
        if s.get_errors
          IngestUtilities.add_error(self, s.get_errors, true)
        end
      end

      if self.validate_only || self.overwrite || self.read_only || !IngestUtilities.already_loaded?(self)
        parse_and_load_stix(raw_xml, options)
        
        package=self.stix_packages.first

        unless package.nil?
          
          # Store the the source feed received from FLARE if FLARE sent this
          # information with the file. This ultimately comes from a string
          # property in the AMQP message received from FLARE. For HR files,
          # this is stored in the uploaded_file and added to the package
          # upon full ingestion after HR approval.
          package.src_feed = self.src_feed if self.src_feed.present?
          audit = Audit.basic
          audit.message = "Package created from STIX upload: #{self.file_name}."
          audit.details = "#{package.uploaded_file.guid}"
          audit.item = package
          audit.audit_type = :upload
          package.audits << audit
          package.updated_at = Time.now
          package.save
        end
      else
        IngestUtilities.add_error(self, "STIX Package has already been successfully loaded.")
      end
    else
      IngestUtilities.add_error(self, "Not a STIX XML File: #{self.file_name}")
    end

    # if its an api upload, try and set the name to the name of the package title
    if self.file_name == 'API Upload'
      if self.stix_packages.first.present?
        self.file_name = "API Upload (#{self.stix_packages.first.title})"
      else
        if [
             OriginalInput::XML_DISSEMINATION_ISA_FILE,
             OriginalInput::XML_DISSEMINATION_AIS_FILE,
             OriginalInput::XML_DISSEMINATION_CISCP_FILE,
             OriginalInput::XML_DISSEMINATION_TRANSFER,
             OriginalInput::XML_AIS_XML_TRANSFER
         ].include?(oi.input_sub_category)
          stix_id = options[:stix_id] ||
              /id=["'](.+?)["']/.match(oi.raw_content)
          stix_id = "#{stix_id} - #{oi.input_sub_category}"
        else
          stix_id = /id=["'](.+?)["']/.match(oi.raw_content)
        end

        self.file_name = "API Upload (#{stix_id})"
      end
    end

    # set the uploaded files portion marking when all done.
    self.set_portion_marking

    self.save
    IngestUtilities.cleanup(self, @file_path)
  rescue  Exception => e
    ExceptionLogger.debug("exception: #{e}, message: #{e.message}, backtrace: #{e.backtrace}")
    IngestUtilities.add_error(self, "#{e.backtrace.first}: #{e.message} (#{e.class})")
    self.save
    IngestUtilities.cleanup(self, @file_path)
  end

  # Uploads a WeatherMap heatmap image. There will be rows created in three
  # tables. UploadedFile will record the status of the upload and any errors
  # or warnings. OriginalInput will be used to store the image in the 
  # database. And WeatherMapImage will store metadata about the image,
  # including the organization token and a foreign key to OriginalInput.

  def upload_weathermap_image(upload, current_user_guid, org_token, options={})
    return if upload.length==0
    self.init_uploaded_file(upload, 'WeatherMap Image', current_user_guid,
      options)

    oi = XmlSaving.store_original_file(@file_path, self.guid, @input_category, @mime_type) if is_file_upload
    oi = XmlSaving.store_original_input(upload, self.guid, @input_category, @mime_type) if !is_file_upload

    # Store the WeatherMap Images record
    WeatherMapImage.create(organization_token: org_token, image_id: oi.id)

    self.status = ActionStatus::SUCCEEDED
    self.save
    IngestUtilities.cleanup(self, @file_path)
  rescue  Exception => e
    IngestUtilities.add_error(self, "#{e.backtrace.first}: #{e.message} (#{e.class})")
    ExceptionLogger.debug("exception: #{e}, message: #{e.message}, backtrace: #{e.backtrace}")
    self.save
    IngestUtilities.cleanup(self, @file_path)
  end

  def upload_zip_file(upload, current_user_guid, options)
    self.init_uploaded_file(upload, 'Zip File', current_user_guid, options)

    oi = XmlSaving.store_original_file(@file_path, self.guid, @input_category, @mime_type) if is_file_upload
    oi = XmlSaving.store_original_input(upload, self.guid, @input_category, @mime_type) if !is_file_upload

    self.status = ActionStatus::SUCCEEDED
    self.save
    IngestUtilities.cleanup(self, @file_path)
  rescue  Exception => e
    IngestUtilities.add_error(self, "#{e.backtrace.first}: #{e.message} (#{e.class})")
    ExceptionLogger.debug("exception: #{e}, message: #{e.message}, backtrace: #{e.backtrace}")
    self.save
    IngestUtilities.cleanup(self, @file_path)
  end

  def store_amqp_replicated_upload(uploaded_xml, amqp_user, options={})
    if AppUtilities.is_ciap_dms_1b_or_1c_arch?
      self.replicate = true
    else
      self.replicate = false
    end

    # set AVP Valid true because if it comes from amqp replication it should be flare_relay
    self.avp_valid = true

    upload_options = {validate_only: false, overwrite: false}
    if options[:transfer_category].present?
      upload_options[:transfer_category] = options[:transfer_category]
      # Overwrite is allowed for transformed files replicated via AMQP from CIAP
      # to ECIS for immediate dissemination because a retry of a file that
      # failed outbound dissemination and was not acknowledged needs to be
      # allowed to pass right through.
      upload_options[:overwrite] = [
          OriginalInput::XML_DISSEMINATION_ISA_FILE,
          OriginalInput::XML_DISSEMINATION_AIS_FILE,
          OriginalInput::XML_DISSEMINATION_CISCP_FILE
      ].include?(upload_options[:transfer_category])
      upload_options[:stix_id] = options[:dissemination_labels]['stix_id'] if
          options[:dissemination_labels].present?
    end

    self.upload_data_file(uploaded_xml, amqp_user.guid, upload_options)

    AisStatisticLogger.debug("[uploads][AisStatistics]: Preparing to log uploaded file result for AIS Statistic")
    ais_statistics, system_tags = AisStatistic.log_uploaded_file_result(self)
    # We only need to replicate on ECIS to ciap
    if ais_statistics.present? && AppUtilities.is_ecis_dms_1b_or_1c_arch?
      AisStatisticLogger.debug("[uploads][AisStatistics]: Ais Statistic is present, Preparing to Replicate")
      ReplicationUtilities.replicate_ais_statistics(ais_statistics, 'ais_statistic_forward')
      AisStatisticLogger.debug("[uploads][AisStatistics]: Replicated")
    end

    if self.status == 'S'
      true
    elsif self.status == 'F'
      # Redact file name if on classified system
      if Setting.CLASSIFICATION == true
        self.update_columns({:file_name => UploadedFile::FAILED_FILE_NAME, :portion_marking => 'UNKNOWN'})
      end
      false
    else
      false
    end
  end

  protected

    def init_uploaded_file(upload, input_category, current_user_guid, options = {})
      # Zero out our data arrays
      @skip_validations ||= []
      @incoming_objects ||= []
      @replicate = true if @replicate.nil?
      @input_category = input_category
      if @input_category == 'Attachment'
        @mime_type = options[:mime_type]
      elsif @input_category == 'Upload'
        @mime_type = 'text/stix'
      elsif @input_category == 'WeatherMap Image'
        @mime_type = options[:mime_type] || 'image/jpeg'
      elsif @input_category == 'Zip File'
        @mime_type = options[:mime_type]
      end

      @is_file_upload = (upload.class == String) ? false : true
  
      # Store the initial UploadedFile record
      self.status = ActionStatus::IN_PROGRESS

      unless options[:human_review_approved] == true
        if @is_file_upload
          # Prevents potential directory switching attack
          self.file_name = upload.original_filename.gsub("\.\.", '')
          self.file_size = upload.size
          # Record this convenient value for use throughout the code
          @file_path = upload.path
        else
          if options[:use_file_name]
            self.file_name = options[:use_file_name]
          else
            self.file_name = 'API Upload'
          end
          self.file_size = upload.size
          @file_path = nil
        end

        self.user_guid = current_user_guid
      end

      self.validate_only = options[:validate_only].present? ? options[:validate_only] : false
      self.overwrite = options[:overwrite].present? ? options[:overwrite] : false
      self.read_only = options[:read_only].present? ? options[:read_only] : false
      # The options are mutually exclusive so the safest options wins.
      if self.overwrite && self.validate_only
        self.overwrite = false
        IngestUtilities.add_warning(self, "Option Conflict: Cannot do validate_only AND overwrite " +
          "- defaulting to validate_only")
      end
      self.save!
    end

    # Loads data from parsed STIX objects into the database.
    def load_from_stix(lst, current_user_guid, options = {})
      Ingest.store_stix_data(self, lst, current_user_guid, options)
      if self.error_messages.size == 0
        self.status = ActionStatus::SUCCEEDED
      else
        self.status = ActionStatus::FAILED
        return false
      end

      return true
    end

    # Parses STIX XML and loads data into the database, returning an instance
    # of the top-level Package.

    def parse_and_load_stix(str, options = {})
      hr_needed = human_reviewable?(str)
      xml = str

      if (AppUtilities.is_ciap_dms_1b_or_1c_arch? ||
          AppUtilities.is_ecis_legacy_arch?) &&
          !Stix::Stix111::PackageInfo.is_ciscp?(xml, Setting.CISCP_ID_PATTERNS)
        # Only sanitizes if needed
        xml = Sanitization.new.sanitize(self, str, hr_needed)
      end

      if hr_needed
        objs = self.parse_stix(xml, options)

        if objs.blank?
          IngestUtilities.add_error(self, "STIX Parse Failure: #{self.file_name}")
          self.status = ActionStatus::FAILED
          return
        end

        if AppUtilities.is_ciap_dms_1b_or_1c_arch? ||
            AppUtilities.is_ecis_legacy_arch?
          # Path 2: ECIS Sanitization -> CIAP
          if AppUtilities.is_ecis?
            IngestUtilities.add_warning(self, "Human Review Transfer Needed")
            self.validate_only = true
            self.human_review_needed = true
          else
            self.human_review_needed = true if !self.validate_only
          end

          if objs.present?
            self.load_from_stix(objs, self.user_guid, options)
          end
        end

        if self.status == ActionStatus::SUCCEEDED
        
          if AppUtilities.is_ciap? && !validate_only              # Path 1: For CIAP Human Review
            load_human_review(xml)
          end

          # Send the sanitized version over first.  This needs to happen after parsing incase parsing fails.
          oi = self.original_inputs.active.where(:input_sub_category => "Sanitized").first
          if AppUtilities.is_ciap_dms_1b_arch? && AppUtilities.is_amqp_sender?
            # Replicate a sanitized copy of the xml from CIAP to ECIS in the
            # DMS 1b architecture.
            ReplicationUtilities.replicate_xml(oi.utf8_raw_content, oi.id,
                                               'publish', nil,
                                               OriginalInput::XML_DISSEMINATION_TRANSFER, false,
                                               oi.dissemination_labels)
          elsif AppUtilities.is_ciap_dms_1b_arch?
            # Replicate a sanitized copy of the xml from CIAP to ECIS in the
            # DMS 1b architecture.
            ReplicationUtilities.replicate_xml(oi.utf8_raw_content, oi.id,
                                               'publish')
          elsif AppUtilities.is_ciap_dms_1c_arch? && AppUtilities.is_amqp_sender?
            # Replicate a sanitized copy of the xml from CIAP to ECIS with
            # dissemination labels in the DMS 1c architecture.
            if Setting.DISSEMINATION_TRANSFORMING_ENABLED
              ReplicationUtilities.disseminate_xml(oi.utf8_raw_content,
                                                   oi.id, 'publish',
                                                   oi.dissemination_labels, false)
            else
              ReplicationUtilities.replicate_xml(oi.utf8_raw_content,
                                                 oi.id,
                                                 'publish', nil,
                                                 OriginalInput::XML_DISSEMINATION_TRANSFER, false,
                                                 oi.dissemination_labels)
            end
          end
        end

      # Setting.MODE needs to be here because CIR Could exist still.  This path should only be taken if its ECIS in DMS1b+ architecture
      elsif AppUtilities.is_ecis_dms_1b_or_1c_arch? # Path 3: ECIS Sanitized
        begin
          # If the uploaded file is not reloaded, it will not have any
          # original_inputs here since the creation merely sets the guid of
          # the uploaded file and saves the original input. This will cause
          # the input_sub_category to remain nil instead of being set to the
          # transfer_category or XML_UNICORN as appropriate for AMQP uploads.
          self.reload
          oi = self.original_inputs.active.first

          oi.input_sub_category = [
              OriginalInput::XML_AIS_XML_TRANSFER,
              OriginalInput::XML_DISSEMINATION_ISA_FILE,
              OriginalInput::XML_DISSEMINATION_AIS_FILE,
              OriginalInput::XML_DISSEMINATION_CISCP_FILE,
              OriginalInput::XML_DISSEMINATION_TRANSFER
          ].include?(options[:transfer_category]) ?
              options[:transfer_category] : OriginalInput::XML_UNICORN
          oi.save!
          self.status = ActionStatus::SUCCEEDED
        rescue StandardError => e
          if e.kind_of?(Array)
            IngestUtilities.add_error(self, "#{e.message.first} (#{consent_marking.class})")
          else
            IngestUtilities.add_error(self, "#{e.message} (#{consent_marking.class})")
          end
          ExceptionLogger.debug("exception: #{e}, message: #{e.message}, backtrace: #{e.backtrace}")
          self.status = ActionStatus::FAILED
        end
      else                                    # Path 4: Normal Load
        objs = self.parse_stix(xml, options)
        if objs.present?
          # If overwrite option is set
          overwritten_pkg_guids =
              IngestUtilities.overwrite_older_packages(self)
          # Store the previous guid in the Stix::Native::Package id field so
          # it can be restored during ingest in order to link audit histories.
          objs.first.id =
              overwritten_pkg_guids.first if overwritten_pkg_guids.present?

          # If a package doesnt need human review it is final
          self.final = true if AppUtilities.is_ciap?

          self.load_from_stix(objs, self.user_guid, options)
        else
          IngestUtilities.add_error(self, "STIX Parse Failure: #{self.file_name}")
          self.status = ActionStatus::FAILED
        end
      end
    end

    # Load Human Review data to support the Human Review feature.
    def load_human_review(xml)
      self.human_review_needed = true
      IngestUtilities.overwrite_older_packages(self)
      hr = HumanReview.load_human_review(xml, self.id)
      XmlSaving.update_original_xml(nil, self.guid, OriginalInput::XML_HUMAN_REVIEW_PENDING)

      if hr.present? and !hr.data_errors.present?
        IngestUtilities.add_warning(self, "Human Review Pending")
        self.status = ActionStatus::SUCCEEDED
      else
        if hr.present? && hr.data_errors.present?
          IngestUtilities.add_error(self, hr.data_errors, true)
        end
        IngestUtilities.add_error(self, "Human Review Load Failure: #{self.file_name}")
      end
    end

    # Parse STIX XML and return an array of parsed objects.
    def parse_stix(xml, options = {})
      p = Stix::Stix111::Parser.new(Setting.XML_PARSING_LIBRARY.to_s.to_sym)
      options[:ciscp_id_patterns] =
          Setting.CISCP_ID_PATTERNS unless absent?(Setting.CISCP_ID_PATTERNS)
      parse_start_time = Time.now
      UploadLogger.info("[Upload][parse] Started parsing XML file at: #{parse_start_time}.")
      lst = p.parse(xml, options)
      parse_end_time = Time.now
      UploadLogger.info("[Upload][parse] Completed parsing of XML file at: #{parse_end_time}. Parsing started at: #{parse_start_time}. Total parsing time in seconds: #{ parse_end_time.to_i - parse_start_time.to_i }")
      self.human_review_needed = true if p.human_review_needed? && !validate_only
      IngestUtilities.add_warning(self, p.warnings, true)
      if !p.valid?
        IngestUtilities.add_error(self, p.errors, true)
        return nil
      end
      lst
    end

  private
  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    text :file_name
    string :file_name
    time :created_at, stored: false
    text :guid, as: :text_exact
    string :status
    string :user_guid

    text :avp_errors do
      avp_message.present? ? avp_message.avp_errors : nil
    end

    text :avp_prohibited do
      avp_message.present? ? avp_message.prohibited : nil
    end
  end
end
