class Sanitization

  def initialize
    @warnings=nil
    @errors=nil
  end

  # Validate that the ids, idrefs, and object_references in the raw_content xml
  # of the original_input object are in valid formats, updating the
  # raw_content xml accordingly to correct issues found. Add warnings to
  # alert the user of changes and/or errors.

  def sanitize_id_format_raw_xml(original_input)
    return nil if original_input.nil? || original_input.raw_content.blank?
    format_sanitizer = Stix::Stix111::SanitizerValidFormat.new(Setting.XML_PARSING_LIBRARY.to_s.to_sym)
    format_sanitizer.sanitize_xml(original_input.raw_content)
    @warnings = format_sanitizer.warnings
    if format_sanitizer.valid?
      original_input.raw_content = format_sanitizer.xml
    else
      @errors = format_sanitizer.errors
      nil
    end
  end

  def sanitize(object, xml, hr_needed = false)
    stix_sanitizer = CiapSanitizer.new
    san = Stix::Stix111::Sanitizer.new(Setting.XML_PARSING_LIBRARY.to_s.to_sym, stix_sanitizer)
    
    str = xml
    first_oi = object.original_inputs.active.first
    input_category = first_oi.input_category
    mime_type = first_oi.mime_type
    sanitize_nccic_ids = sanitize_nccic_ids?

    xml_hash=Hash.from_xml(str)
    original_stix_package_id = xml_hash['STIX_Package']['id']
    if hr_needed == false
      str = san.sanitize(str, {ids: true, descriptions: false,
                                 nccic_ids: sanitize_nccic_ids})
      # If we created any mappings, link them to the original input
      # Array should be unique by definition, but it doesn't hurt to make sure
      mapped_ids = stix_sanitizer.mappings.values.collect { |mapping|
        mapping[:persisted_id]
      }.uniq

      XmlSaving.update_original_xml(str, object.guid,
                                        OriginalInput::XML_UNICORN,
                                        mapped_ids)
    else      
      str = san.sanitize(str, {ids: true, descriptions: false,
                                 nccic_ids: sanitize_nccic_ids})
      # If we created any mappings, link them to the original input
      # Array should be unique by definition, but it doesn't hurt to make sure
      mapped_ids = stix_sanitizer.mappings.values.collect { |mapping|
        mapping[:persisted_id]
      }.uniq

      if AppUtilities.is_ecis_legacy_arch?
        XmlSaving.update_original_xml(str, object.guid,
                                          OriginalInput::XML_HUMAN_REVIEW_TRANSFER,
                                          mapped_ids)
      end

      str2 = san.sanitize(str, {ids: false, descriptions: true})

      oi = XmlSaving.store_original_input(str2, object.guid, input_category,
                                          mime_type, nil, nil,
                                          OriginalInput::XML_SANITIZED,
                                          mapped_ids)

      if oi
        object.original_inputs << oi
        object.validate_only = true if AppUtilities.is_ecis?
      end
    end

    str
  end

  def get_warnings
    @warnings
  end

  def get_errors
    @errors
  end

private

  # To prevent re-sanitization of ids already prefixed with NCCIC, ids
  # already possessing this prefix are only subject to sanitization if
  # the source is an AIS provider. If the source is an AIS provider, the
  # id mappings in the database will will be checked to see if the
  # NCCIC-prefixed id is on the after side of an id mapping, which
  # confirms that this id was indeed previously generated from
  # sanitization. If such an id mapping is found in the database,
  # re-sanitization will not occur for this id. If the source is not an
  # AIS provider (e.g., a UI upload). NCCIC-prefixed ids will be
  # excluded from the XPath queries using to locate ids for sanitization
  # and will not be subject to sanitization at all, skipping deeper
  # checks for re-sanitization. For files from such sources, NCCIC-prefixed
  # ids will be automatically assumed as either not needing sanitization
  # at all or needing to have re-sanitization explicitly blocked by the
  # mere existence of the NCCIC prefix. This method returns true if
  # NCCIC-prefixed ids should be considered for sanitization (subject to the
  # re-sanitization-prevention rules) or false if they should be excluded
  # entirely.
  def sanitize_nccic_ids?
    return false if User.current_user.nil?
    if AppUtilities.is_ciap_dms_1b_or_1c_arch?
      # In the DMS 1b+ architecture, CIAP performs all sanitization. To
      # determine if a file came from an AIS provider, the
      # Ingest.is_ais_provider_user? method is used to check if the current
      # username for this session matches one of the comma-separated usernames
      # in the AIS_PROVIDER setting.
      Ingest.is_ais_provider_user?(User.current_user)
    elsif AppUtilities.is_ecis_legacy_arch?
      # In the legacy architecture, ECIS performs all sanitization. To
      # determine if a file came from an AIS provider, the
      # Ingest.is_ais_provider_user? method is used to check if the current
      # username for this session matches one of the comma-separated usernames
      # in the AIS_PROVIDER setting if this setting is defined as a
      # performance enhancement. If that test fails, it will check if the
      # current user's api key matches the the api key of the
      # user for replications of the "stix_forward" repl_type.
      Ingest.is_ais_provider_user?(User.current_user) ||
          Replication.where(repl_type: 'stix_forward',
                            api_key: User.current_user.api_key).first.present?
    else
      # Sanitization does not occur on CIAP in the legacy architecture or on
      # ECIS in the DMS 1b+ architecture so return false.
      false
    end
  end

end
