class UploadsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    unless can_view(current_user)
      render json: {errors: ["You do not have the ability to view uploads"]}, status: 403
      return
    end

    admin_search = false
    if params[:admin] && params[:admin].to_bool == true && User.has_permission(current_user,'view_all_uploads')
      admin_search = true
      @uploaded_files = UploadedFile.all
    else
      @uploaded_files = UploadedFile.stix_uploads.where(:user_guid => current_user.guid)
    end

    limit = record_limit(params[:amount].to_i)
    offset = params[:offset] || 0

    if params[:q].present?
      search = Search.uploads_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (limit || Sunspot.config.pagination.default_per_page),
        offset: offset,
        admin_search: admin_search,
        user_guid: current_user.guid
      })
      total_count = search.total
      @uploaded_files = search.results

      @uploaded_files ||= []
    else
      @uploaded_files ||= UploadedFile.stix_uploads.reorder(updated_at: :desc)

      @uploaded_files = @uploaded_files.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @uploaded_files = @uploaded_files.where(file_name: params[:file_name]) if params[:file_name]
      @uploaded_files = apply_sort(@uploaded_files, params)
      total_count = @uploaded_files.count
      @uploaded_files = @uploaded_files.limit(limit).offset(offset)
    end
    @metadata = Metadata.new
    @metadata.total_count = total_count
    render json: {metadata: @metadata, uploads: @uploaded_files}
  end

  def show
    unless can_view(current_user)
      render json: {errors: ["You do not have the ability to view uploads"]}, status: 403
      return
    end
    # Retrieve the record from the database with associated errors/warnings
    @uploaded_file = UploadedFile.where(:id => params[:id]).first
    if @uploaded_file.present?
      render json: @uploaded_file
    else
      render json: {errors: ["Could not find upload  with ID: #{params[:id]}"]}, status: 404
    end
  end

  def new
    unless can_upload(current_user)
      render json: {errors: ["You do not have the ability to view uploads"]}, status: 403
      return
    end
  end

  def create
    unless can_upload(current_user)
      render json: {errors: ["You do not have the ability to upload"]}, status: 403
      return
    end

    # If we want to check the mime type we can do this.
    # params[:file].content_type
    
    # if its not an api upload.
    if params['file']
      if params[:file].tempfile.path.include?('.')
        file_ext = params[:file].tempfile.path[params[:file].tempfile.path.rindex('.')...params[:file].tempfile.path.length]
      else
        file_ext = 'Blank File Type'
      end

      unless UploadedFile::UPLOAD_ACCEPTED_FILE_TYPES.include?(file_ext.downcase)
        render json: {errors: ["Could not upload file, Unaccepted file type (" + file_ext + ")"]}, status: 415
        return
      end
    end

    body = request.body.read
    request.body.rewind

    if params['file']
      upload = params['file']
    else # An API request
      upload = body
    end

    @uploaded_file = UploadedFile.new
    @uploaded_file.replicate = params[:forward]

    @uploaded_file.avp_validation = params[:avp_validation].to_bool && User.current_user.username != "flare_relay"
    @uploaded_file.avp_fail_continue = params[:avp_fail_continue]
    @uploaded_file.avp_valid = params[:avp_valid].to_bool || nil
    @uploaded_file.avp_message_id = params[:avp_message_id]

    if params[:canceled].to_bool
      @uploaded_file.status = "C"
      @uploaded_file.file_name = "Canceled Upload: " + upload.original_filename.gsub("\.\.", '')
      @uploaded_file.user_guid = User.current_user.guid
      @uploaded_file.save!
      render json: @uploaded_file, status: 200
      return
    end

    if AppUtilities.is_ciap? && Setting.FLARE_AVP_PATH.present? && @uploaded_file.avp_validation == true && params[:continue].to_bool == false
      @avp_message = AvpMessage.send_to_avp(File.open(upload.path,"rb").read, {'Content-type'=>'text/xml'})
      
      if (@avp_message.class == AvpMessage && @avp_message.avp_errors.blank? && @avp_message.prohibited.blank?) || @uploaded_file.avp_fail_continue
        @uploaded_file.avp_valid = @avp_message.avp_valid
        @uploaded_file.avp_message_id = @avp_message.id
      else
        render json: @avp_message, status: 300
        return
      end
    end

    if @uploaded_file
      @uploaded_file.upload_data_file(upload, current_user.guid, collate_upload_options(params))

      if @uploaded_file.status == 'S'

        render json: @uploaded_file, status: 201

        # If the Human Review and Sanitization is being done on the same system (CIAP), then we need to send the Sanitized version to
        # ECIS.  Otherwise, we need to do the transfer the original way

        # Sanitization replication was moved into the sanitization service.  This is due to the way the amqp receiver works.  It does not hit the controller

        if AppUtilities.is_ciap_dms_1b_or_1c_arch?
          if AppUtilities.is_amqp_sender? &&
              @uploaded_file.stix_packages.present?
            package = @uploaded_file.stix_packages.first
            # Render the AIS XML equivalent of a MIFR file if it has
            # appropriate AIS markings for dissemination and then replicate it
            # to ECIS.
            if package.present? && package.title.to_s.start_with?('MIFR-') &&
                package.fd_ais?
              ais_xml = render_to_string(partial: 'stix_packages/show.ais.erb',
                                         locals: {stix_package: package})

              if AppUtilities.is_ciap_dms_1b_arch?
                ReplicationUtilities.replicate_xml(ais_xml, package.stix_id,
                                                 'publish', nil,
                                                 OriginalInput::XML_AIS_XML_TRANSFER, @uploaded_file.final)
              elsif AppUtilities.is_ciap_dms_1c_arch?
                if Setting.DISSEMINATION_TRANSFORMING_ENABLED
                  ReplicationUtilities.disseminate_xml(ais_xml,
                                                       package.stix_id,
                                                       'publish',
                                                       OriginalInput.dissemination_labels_from_ais_xml(ais_xml), @uploaded_file.final)
                else
                  ReplicationUtilities.replicate_xml(ais_xml,
                                                    package.stix_id,
                                                    'publish', nil,
                                                    OriginalInput::XML_DISSEMINATION_TRANSFER, @uploaded_file.final,
                                                    OriginalInput.dissemination_labels_from_ais_xml(ais_xml))
                end
              end
            end
          end
        elsif AppUtilities.is_ecis_legacy_arch? && params[:forward] != 'N' &&
            params[:forward] != 0
          # Replications of repl_type "stix_forward" only exist on ECIS and
          # are only necessary in the legacy architecture so only do the
          # database operations to determine if replication is necessary on ECIS
          # in legacy architecture mode when forwarding isn't explicitly
          # disabled.
          original_input =
              @uploaded_file.original_inputs.where({input_category: 'Upload',
                                                    input_sub_category: [OriginalInput::XML_HUMAN_REVIEW_TRANSFER, OriginalInput::XML_UNICORN]}).first
          if original_input.present?
            ReplicationLogger.debug("[uploads][replicate?]: status: #{@uploaded_file.status}, input_sub_category: #{original_input.input_sub_category}, params: #{params[:forward]}, will_replicate: true")
            ReplicationUtilities.replicate_xml(original_input.utf8_raw_content,
                                             original_input.id, 'stix_forward', current_user, nil, @uploaded_file.final)
          end
        end
      elsif @uploaded_file.status == 'F'
        # Redact file name if on classified system
        if Setting.CLASSIFICATION == true
          @uploaded_file.update_columns({:file_name => UploadedFile::FAILED_FILE_NAME, :portion_marking => 'UNKNOWN'})
        end
        render json: @uploaded_file, status: 406
      end
      if @uploaded_file.present?
        AisStatisticLogger.debug("[uploads][AisStatistics]: Preparing to log uploaded file result for AIS Statistic")
        ais_statistics, system_tags = AisStatistic.log_uploaded_file_result(@uploaded_file)
        # We only need to replicate on ECIS to ciap
        if ais_statistics.present? && AppUtilities.is_ecis?
          AisStatisticLogger.debug("[uploads][AisStatistics]: Ais Statistic is present, Preparing to Replicate")
          ReplicationUtilities.replicate_ais_statistics(ais_statistics, 'ais_statistic_forward')
        end
      end
    else
      render json: {errors: ["Could not find upload  with ID: #{params[:id]}"]}, status: 404
    end
  end

  def display_original_xml
    unless User.has_permission(current_user, 'human_review')
      render json: {errors: ['You do not have the ability to view XML']}, status: 403
      return
    end

    @uploaded_file = UploadedFile.find_by_guid(params['id'])
    if @uploaded_file.blank?
      @uploaded_file = UploadedFile.find_by_id(params['id'])
    end
    
    if @uploaded_file.present?
      if params[:human_review] == 'true'
        original_input = @uploaded_file.original_inputs.active.first
      else
        original_input = @uploaded_file.original_inputs.source
      end
      
      if original_input.present?
        render xml: original_input.utf8_raw_content
      else
        render json: {errors: ["Uploaded file with ID: #{params[:id]} doesn't exist"]}, status: 404
      end
    else
      render json: {errors: ["Uploaded file with ID: #{params[:id]} doesn't exist"]}, status: 404
    end
  end

  def attachment

    # If we want to check the mime type we can do this.
    # params[:file].content_type

    if params[:file].tempfile.path.include?('.')
      file_ext = params[:file].tempfile.path[params[:file].tempfile.path.rindex('.')...params[:file].tempfile.path.length]
    else
      file_ext = 'Blank File Type'
    end

    unless UploadedFile::ATTACHMENTS_ACCEPTED_FILE_TYPES.include?(file_ext.downcase)
      render json: {errors: ["Could not attach file, Unaccepted file type (" + file_ext + ")"]}, status: 415
      return
    end

    body = request.body.read
    request.body.rewind

    if params['file']
      upload = params['file']
    else # An API request
      upload = body
    end

    indicator_id=URI.decode(params['indicator_id'])

    @uploaded_file = UploadedFile.new

    if @uploaded_file
      @uploaded_file.upload_attachment(upload, current_user.guid, indicator_id, {ref_title: params[:ref_title], ref_num: params[:ref_num], ref_link: params[:ref_link]}, {mime_type: params['file'].content_type})
      @indicator=Indicator.includes(
        :attachments,
        audits: :user,
        confidences: :user,
        related_to_objects: [confidences: :user],
        related_by_objects: [confidences: :user],
        stix_markings: [:isa_marking_structure,:tlp_marking_structure,:simple_marking_structure,{isa_assertion_structure: [:isa_privs,:further_sharings]}]
      ).find_by_stix_id(indicator_id)
      render(json: @indicator) && return
    else
      render json: {errors: ["Could not attach file"]}, status: 404
    end
  end

  def download_attachment
    @attachment = UploadedFile.find(params[:id])
    indicator = @attachment.original_inputs[0].indicator
    audit = Audit.basic
    audit.message = "File #{@attachment.file_name} downloaded"
    audit.item = indicator
    audit.audit_type = :attachment_download
    indicator.audits << audit
    indicator.updated_at = Time.now
    indicator.save
    send_data(@attachment.original_inputs.first.raw_content, :type => @attachment.original_inputs.first.mime_type, :filename => "#{@attachment.file_name}", :disposition => "inline")
  end

  def destroy_attachment
    @attachment = UploadedFile.find(params[:id])
    indicator = @attachment.original_inputs[0].indicator

    # save the indicator id so we can later pull up the indicator with updated info
    indicator_id = indicator.stix_id

    # audit the unattachment
    audit = Audit.basic
    audit.message = "File #{@attachment.file_name} unattached"
    audit.item = indicator
    audit.audit_type = :attachment_unattached

    # save it into the indicator
    indicator.audits << audit
    indicator.updated_at = Time.now
    indicator.save

    # remove the linkage between the attached file and the indicator
    @attachment.original_inputs.each do |e|
      e.remote_object_id = nil
      e.remote_object_type = nil
      e.save
    end

    # get the indicator with its updated data
    @indicator=Indicator.includes(
        :attachments,
        audits: :user,
        confidences: :user,
        related_to_objects: [confidences: :user],
        related_by_objects: [confidences: :user],
        stix_markings: [:isa_marking_structure,:tlp_marking_structure,:simple_marking_structure,{isa_assertion_structure: [:isa_privs,:further_sharings]}]
      ).find_by_stix_id(indicator_id)
    render(json: @indicator) && return
  end

  private

    def can_view(u)
      User.has_permission(u, 'view_uploaded_file_info')
    end

    def can_upload(u)
      User.has_permission(u, 'view_uploaded_file_info') &&
      User.has_permission(u, 'create_indicator_observable') &&
#      User.has_permission(u, 'create_threat_actor') &&
#      User.has_permission(u, 'create_campaign') &&
#      User.has_permission(u, 'create_course_of_action') &&
#      User.has_permission(u, 'create_ttp') &&
      User.has_permission(u, 'create_package_report')
    end

    def collate_upload_options(params)
      options = {}
      if params["validate_only"].present? && params["validate_only"] == 'Y'
        options[:validate_only] = true
      else
        options[:validate_only] = false
      end
      if params["overwrite"].present? && params["overwrite"] == 'Y'
        options[:overwrite] = true
      else
        options[:overwrite] = false
      end

      options
    end

end
