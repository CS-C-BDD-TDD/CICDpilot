# Stores original content that has been reeceived from external sources,
# whether file attachments, uploaded STIX files or STIX content received via
# the API.

class OriginalInput < ActiveRecord::Base
  self.table_name = 'original_input'
  include Guidable
  include Serialized
  include Transferable

  # Allowable sub_category values if the category is 'Upload' and the setting
  # HUMAN_REVIEW_ENABLED == TRUE.

  XML_HUMAN_REVIEW_PENDING = 'Human Review Pending'     # For Human Review
  XML_HUMAN_REVIEW_COMPLETED = 'Human Review Completed' # For full ingestion &
                                                        # transfer to ECIS.

  # Allowable sub_category values if the category is 'Upload' and the setting
  # HUMAN_REVIEW_ENABLED == FALSE.

  XML_HUMAN_REVIEW_TRANSFER = 'Human Review Transfer'   # Sanitized IDs + HR
  XML_SANITIZED = 'Sanitized'                           # Sanitized IDs/Fields
  XML_UNICORN = 'Transfer'                              # Sanitized IDs - A
                                                        # file that does not
                                                        # need HR.
  XML_PII_CLEARED = 'PII Cleared'                       # After 24 hours, the
                                                        # dissemination engine
                                                        # will automatically
                                                        # clear the XML that
                                                        # may contain PII
  XML_AIS_XML_TRANSFER = 'AIS XML Transfer'             # Rendered AIS XML
  XML_DISSEMINATION_TRANSFER = 'Dissemination Transfer' # Transfer for
                                                        # dissemination via AMQP
                                                        # message to either
                                                        # DMS or ECIS for
                                                        # transformation.
  XML_DISSEMINATION_ISA_FILE = 'ISA Dissemination File' # XSLT transformed
                                                        # ISA profile file.
  XML_DISSEMINATION_AIS_FILE = 'AIS Dissemination File' # XSLT transformed
                                                        # AIS profile file.
  XML_DISSEMINATION_CISCP_FILE =
      'CISCP Dissemination File'                        # CISCP file suitable
                                                        # for dissemination.

  before_save :set_fed
  before_create :set_old_uploaded_file_id
  #MUST BE LAST CALLBACK!!!!!!!!!!!
  before_create :calc_sha2_hash

  scope :transfer, -> {where(input_category: 'Upload').
                         where("input_sub_category != ? OR input_sub_category is null", OriginalInput::XML_SANITIZED).first}
  scope :source, -> {where(input_category: 'SOURCE').first}
  scope :active, -> {where.not(input_category: 'SOURCE')}

  def calc_sha2_hash
    # Remove any \r\n or \n from the input file before calculating the sha2
    # hash, so that both UI uploads and API uploads will match
    content = self.raw_content.to_s.gsub(/\r?\n/,"")
    d = Digest::SHA2.new << self.raw_content
    self.sha2_hash = d.to_s
  end

  def raw_content=(raw_content)
    if input_category == 'Upload'
      write_attribute(:raw_content,raw_content.force_encoding('UTF-8'))
    else
      write_attribute(:raw_content,raw_content)
    end
  end

  def raw_content
    if input_category == 'Upload'
      read_attribute(:raw_content).force_encoding('UTF-8')
    else
      read_attribute(:raw_content)
    end
  end

  # Ensures that returned content is UTF-8. Because of the use of a blob, it
  # seems to default to ASCII8 despite the fact that UTF-8 is properly stored
  # in the database. Conversion will fail if the raw content is actually a
  # binary file.

  alias_method :utf8_raw_content, :raw_content

  belongs_to :uploaded_file, primary_key: :guid
  belongs_to :indicator, primary_key: :stix_id, foreign_type: :remote_object_type, foreign_key: :remote_object_id, touch: true, class_name: 'Indicator'
  belongs_to :remote_object, primary_key: :stix_id, foreign_key: :remote_object_id, foreign_type: :remote_object_type, touch: true, polymorphic:true
  has_one :weather_map_image, foreign_key: :image_id

  has_many :original_input_ciap_id_mappings
  has_many :ciap_id_mappings, through: :original_input_ciap_id_mappings

  # Utility function for writing output from the console.

  def write_file(file_name = nil)
    if file_name.nil?
      puts("write_file(file_name): Please provide a base file name for output.")
      return 0
    end

    File.open('CIAP_' + file_name, 'w') { |f| f.write(self.raw_content) }
  end

  # This is here to set the old field properly...needed for now
  def set_old_uploaded_file_id
    self.old_uploaded_file_id=self.uploaded_file.id
  end

  def set_fed
    return unless self.input_category == 'Upload'
    original_xml = self.raw_content
    return if original_xml == 'PII'

    document = Nokogiri::XML(original_xml)

    source_xpath_exp = "//stix:STIX_Package//comment()[contains(.,'SOURCE')]"
    # Return unless there is no SOURCE comment node.
    return unless document.xpath(source_xpath_exp).empty?

    xpath_exp="//stix:STIX_Package"
    nodeset = document.xpath(xpath_exp).first

    package_info = Stix::Stix111::PackageInfo.extract_package_info(original_xml, Setting.CISCP_ID_PATTERNS)

    # Do not update if the file is CISCP.
    return if package_info.is_ciscp

    is_federal = package_info.is_federal

    stream = is_federal ?  " SOURCE: FED " : " SOURCE: OTHER "

    comment = Nokogiri::XML::Comment.new(document,stream)
    nodeset.prepend_child(comment)
    self.raw_content = document.to_xml
  end

  def dissemination_labels
    # If this is an AIS XML Transfer from CIAP, disable CISCP detection
    # by passing nil instead of @ciscp_id_pattterns to the
    # extract_package_info method.
    ciscp_id_patterns = self.input_category == 'Upload' &&
        self.input_sub_category == OriginalInput::XML_AIS_XML_TRANSFER ?
        nil : Setting.CISCP_ID_PATTERNS
    package_info =
        Stix::Stix111::PackageInfo.extract_package_info(self.raw_content,
                                                        ciscp_id_patterns)
    tlp_color = package_info.tlp_color.to_s.upcase

    original_stix_id =
        OriginalInput.original_stix_package_id(self,
                                               package_info.stix_id.to_s)
    if (Setting.SEND_FLARE_IDS || 'PARENT').upcase=='ALL'
      # Convert the ciap_id_mappings into a hash, with original_id as the key and sanitized_id as the value
      id_mappings = Hash[*self.ciap_id_mappings.pluck(:original_id,:sanitized_id).flatten]
    end

    if package_info.is_ciscp
      labels = {
          'is_ciscp' => true,
          'stix_id' => package_info.stix_id.to_s,
          'tlp_color' => tlp_color,
          'uploaded_file_id' => self.uploaded_file.id
      }
      labels['original_stix_id'] =
          original_stix_id if original_stix_id.present?
      if (Setting.SEND_FLARE_IDS || 'PARENT').upcase=='ALL'
        labels['mapped_ids'] = id_mappings if id_mappings.present?
      end
    elsif self.input_category == 'Upload' &&
        %w(WHITE GREEN AMBER).include?(tlp_color) &&
        [
            OriginalInput::XML_SANITIZED,
            OriginalInput::XML_UNICORN,
            OriginalInput::XML_AIS_XML_TRANSFER
        ].include?(self.input_sub_category)
      labels = {
          'is_ciscp' => false,
          'stix_id' => package_info.stix_id.to_s,
          'tlp_color' => tlp_color,
          'consent' => package_info.consent.to_s || 'NONE',
          'is_federal' => package_info.is_federal,
          'uploaded_file_id' => self.uploaded_file.id
      }
      labels['original_stix_id'] =
          original_stix_id if original_stix_id.present?
      if (Setting.SEND_FLARE_IDS || 'PARENT').upcase=='ALL'
        labels['mapped_ids'] = id_mappings if id_mappings.present?
      end
    else
      labels = {}
    end
    labels
  end

  def self.dissemination_labels_from_ais_xml(ais_xml)
    package_info =
        Stix::Stix111::PackageInfo.extract_package_info(ais_xml, nil)

    tlp_color = package_info.tlp_color.to_s.upcase

    if %w(WHITE GREEN AMBER).include?(tlp_color)
      labels = {
          'is_ciscp' => false,
          'stix_id' => package_info.stix_id.to_s,
          'tlp_color' => package_info.tlp_color.to_s.upcase,
          'consent' => package_info.consent.to_s || 'NONE',
          'is_federal' => package_info.is_federal
      }
    else
      labels = {}
    end
    labels
  end

  def self.original_stix_package_id(original_input, stix_package_id)
    return nil unless original_input.present?
    mapping =
        original_input.ciap_id_mappings.find_by_after_id(stix_package_id)
    mapping.present? ? mapping[:before_id] : nil
  end

  def isa_transformed(consent=nil, transformer=nil)
    transformer ||= Stix::Xslt::Transformer.new
    consent ||=
        Stix::Stix111::PackageInfo.extract_consent(self.utf8_raw_content)
    xml_isa = transformer.transform_stix_xml(self.utf8_raw_content, 'isa',
                                             consent, true)
    {
        xml: transformer.errors.present? ? nil :
            xml_isa.force_encoding('UTF-8'),
        errors: transformer.errors
    }
  end

  def ais_transformed(consent=nil, transformer=nil)
    transformer ||= Stix::Xslt::Transformer.new
    consent ||=
        Stix::Stix111::PackageInfo.extract_consent(self.utf8_raw_content)
    xml_ais = transformer.transform_stix_xml(self.utf8_raw_content, 'ais',
                                             consent, false)
    {
        xml: transformer.errors.present? ? nil :
            xml_ais.force_encoding('UTF-8'),
        errors: transformer.errors
    }
  end
end
