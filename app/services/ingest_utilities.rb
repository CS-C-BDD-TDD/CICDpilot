class IngestUtilities
	class << self
    def create_status_badge(parent, badge_name, status=nil, system=false)
      badge = BadgeStatus.new
      badge.remote_object = parent
      badge.badge_name = badge_name
      badge.badge_status = status
      badge.system = system
      begin
        badge.save!
      rescue Exception => e
        ExceptionLogger.debug("exception: #{e}, message: #{e.message}, backtrace: #{e.backtrace}")
      end

      badge
    end

		# Return the object that should be used, either the (unsaved) parameter
		# or an existing (and qualifying) object in the database if it already
		# exists.
	  def swap_if_needed(uploaded_file, x, to_save, params = {})
	    orig = self.existing(uploaded_file, x, to_save, params)
	    orig.nil? ? x : orig
	  end

	  # spoof the swap if needed method when doing duplication checks needed at certain times.
	  def spoof_swap(uploaded_file, obj, read_only_obj, read_only, overwrite, to_save)
	    uploaded_file.overwrite = false
	    uploaded_file.read_only = false
	    obj.read_only = false
	    temp_obj = self.swap_if_needed(uploaded_file, obj, to_save)
	    uploaded_file.overwrite = overwrite
	    uploaded_file.read_only = read_only
	    obj.read_only = read_only_obj

	    temp_obj
	  end

	  def remove_duplicate_observables(to_save)
	    to_save2=to_save
	    c_o_ids={}
	    to_save.each do |x|
	      if x.respond_to?(:cybox_object_id)
	        if x.model_name != "Observable"
	          if c_o_ids[x.cybox_object_id]
	            to_save2-=[x]
              # -=[x] removes all instances of x so we need to add one back in.
              to_save2 << x
	          else
	            c_o_ids[x.cybox_object_id]=1
	          end

	        end
	      end
	    end

	    to_save2
	  end

    # Returns true if the STIX file has already been successfully loaded.
    def already_loaded?(uploaded_file)
      uploaded_file.reload
      originals = uploaded_file.original_inputs
      return false unless originals.present?
      sha2_hashes = []
      originals.each do |orig|
        return false if orig.nil? || orig.sha2_hash.nil?
        sha2_hashes << orig.sha2_hash
      end

      return false if sha2_hashes.empty?

      UploadedFile.joins(:original_inputs)
          .where(status: 'S')
          .where(validate_only: false)
          .where(original_input: {sha2_hash: sha2_hashes,
                                  mime_type: 'text/stix'}).count > 0
    end

    # Overwrites other instances of the package that were previously uploaded.
    # It deletes the packages and the indicators, but leaves the observables
    # and CYBOX objects intact. An array containing the guids of overwritten
    # packages is returned.
    def overwrite_older_packages(uploaded_file)
      return [] unless uploaded_file.overwrite || uploaded_file.read_only
      originals = uploaded_file.original_inputs
      return [] unless originals.present?
      sha2_hashes = []
      originals.where('input_sub_category != ? OR input_sub_category is null',
                      OriginalInput::XML_SANITIZED).reject { |orig|
        orig.nil? || orig.sha2_hash.nil? }.each { |orig|
        sha2_hashes << orig.sha2_hash
      }

      return [] if sha2_hashes.empty?

      lst = UploadedFile.joins(:original_inputs)
                .where(validate_only: false)
                .where(original_input: {sha2_hash: sha2_hashes, mime_type: 'text/stix'}).all

      overwritten_pkg_guids = []

      lst.each do |u|
        u.update_attribute(:status, 'R') if u.status!='I'
        p = StixPackage.where(uploaded_file_id: u.guid).first
        unless p.nil?
          overwritten_pkg_guids << p.guid if p.guid.present?
          p.indicators.destroy_all
          p.destroy
        end
      end
      overwritten_pkg_guids.uniq
    end

    # Cleanup activities include removing the physical uploaded file (it's
    # not needed any more because a full copy will be stored in the
    # ORIGINAL_INPUT table) and saving any error messages or warnings to the
    # database.
    def cleanup(uploaded_file, file_path)
      File.delete(file_path) if uploaded_file.is_file_upload

      # clean up old uploads
      cutoff = Time.now - 1.hour
      lst = UploadedFile.where(status: 'I').all
      lst.each do |u|
        u.update_attribute(:status, 'F') if u.updated_at < cutoff
      end
    end

    def add_error(uploaded_file, str, multi = false)
      return unless str.present?
      if multi
        str.each do |mess|
          uploaded_file.error_messages.create(description: mess[0..255])
        end
      else
        uploaded_file.error_messages.create(description: str[0..255])
      end
      uploaded_file.status = ActionStatus::FAILED
    end

    def add_warning(uploaded_file, str, multi = false)
      return unless str.present?
      if multi
        str.each do |mess|
          uploaded_file.error_messages.create(description: mess[0..255], is_warning: true)
        end
      else
        uploaded_file.error_messages.create(description: str[0..255], is_warning: true)
      end
    end

    # Check if the object already exists in the system. Returns the existing
    # object or nil if not found.
    def existing(uploaded_file, x, to_save, params = {})
      #return if uploaded_file.read_only || (Setting.CLASSIFICATION == true && uploaded_file.overwrite)
      obj = nil

      if x.class == Address
        obj = Address.where(
          address_value_normalized: x.address_value_normalized, category: x.category).first || to_save.select {|i| i.respond_to?(:address_value_normalized) && i.address_value_normalized == x.address_value_normalized}.first
      elsif x.class == Domain
        obj = Domain.where(name_normalized: x.name_normalized).first || to_save.select {|i| i.respond_to?(:name_normalized) && i.name_normalized == x.name_normalized}.first
      elsif x.class == Uri
        obj = Uri.where(uri_normalized_sha256: x.uri_normalized_sha256).first || to_save.select {|i| i.respond_to?(:uri_normalized_sha256) && i.uri_normalized_sha256 == x.uri_normalized_sha256}.first
      else
        if x.respond_to?(:cybox_object_id) && x.cybox_object_id.present?
          obj = x.class.where(cybox_object_id: x.cybox_object_id).first || to_save.select {|o| o.respond_to?(:cybox_object_id) && o.cybox_object_id == x.cybox_object_id}.first
        end
      end

      # in the classified enviornment if we have two different classifications we need to preserve both objects
      # to do this we need to check the classifications of the incoming and the existing
      # Otherwise if classifications are the same we need to just return the existing one
      if params[:classification].present? && obj.present? && obj.respond_to?(:stix_markings)
        # we need to differentiate between an existing object in the to_save and a existing saved object.
        cs_class = nil
        # Lets take care of the obj with an id first
        if obj.id.present?
          markings = obj.stix_markings.select {|i| i.isa_assertion_structure.present?}.first
        # next if the object doesnt have an id we need to look for the stix markings associated with it.
        else
          markings = to_save.select{|i| i.class == StixMarking && i.respond_to?(:remote_object_id) && obj.respond_to?(:guid) && i.remote_object_id == obj.guid}.first
        end
          
        if markings.present?
          cs_class = markings.isa_assertion_structure.cs_classification
        end

        if cs_class.present? && cs_class != params[:classification]
          obj = nil
        end
      end

      obj
    end

    def ingest_validations(to_save)
      # remove any nil's
      to_save = to_save.compact

      # any checks we want to do on the array of objects we built
      to_save.each do |obj|
        # check for stix id
        if obj.respond_to?(:stix_id) && obj.stix_id.blank?
            obj.stix_id = SecureRandom.stix_id(obj)
        end

        # check for cybox object id
        if obj.respond_to?(:cybox_object_id) && obj.cybox_object_id.blank?
            obj.cybox_object_id = SecureRandom.cybox_object_id(obj)
        end

        # Check for guids
        if obj.respond_to?(:guid) && obj.guid.blank?
          obj.guid = SecureRandom.uuid
        end

      end

      to_save
    end


    
    def update_confidences(package, uploaded_file)
      oi = uploaded_file.original_inputs.active.first
      
      raw_xml = oi.utf8_raw_content
      updated = false
      
      # Remove any existing confidences from the file            
      xml = Nokogiri::XML(raw_xml)
      xpath_exp="//*[local-name()='Confidence']"
      conf_nodes = xml.search(xpath_exp)
      if conf_nodes.present?
        conf_nodes.remove
        updated = true
      end
      
      # Auto Enrich the original XML with official confidence values
      package.indicators.each {|ind|
        max_conf = nil
        # Collect highest official confidence from each Observable
        ind.observables.each {|obsv|
          new_conf = obsv.latest_confidence
          
          if new_conf.present? and 
             (max_conf.nil? or new_conf.stix_timestamp > max_conf.stix_timestamp)
            max_conf = new_conf
          end
        }
        
        # If an official confidence was found, then insert it into this
        # indicator and into the XML
        if !max_conf.nil?
          c = Confidence.new(
            value: max_conf.value,
            description: max_conf.description,
            source: max_conf.source,
            is_official: max_conf.is_official,
            stix_timestamp: max_conf.stix_timestamp,
            from_file: max_conf.from_file
          )
          ind.confidences << c
        
          # Render the confidence to a string
          conf_str = ActionView::Base.new(ActionController::Base.view_paths).render(partial: 'confidences/show.stix.erb',
              locals: {type: 'indicator', confidences: [c]})
  
          # Update XML to include the confidence
          conf_xml = Nokogiri::XML.fragment(conf_str).elements.first
          xpath_exp="//*[local-name()='Indicator' and @id='#{ind.stix_id}']"
          ind_node = xml.xpath(xpath_exp).first
          
          ind_node.add_child(conf_xml) if ind_node.present?
          updated = true  
        end
      }
      
      if updated
        oi = XmlSaving.update_uploads_xml(xml.to_xml, uploaded_file.guid)
      end
      
      oi
    end

    def update_sightings(package, uploaded_file)
      oi = uploaded_file.original_inputs.active.first
      
      raw_xml = oi.utf8_raw_content
      updated = false
      xml = Nokogiri::XML(raw_xml)
      
      # Auto Enrich the original XML with number of sightings in CIAP
      package.indicators.each {|ind|
        total_sights = 0
        
        # Collect sightings from each Observable
        ind.observables.each {|obsv|
          total_sights = total_sights + obsv.total_sightings
        }

        # Look to see if the indicator already has sightings            
        xpath_exp="//*[local-name()='Indicator' and @id='#{ind.stix_id}']/*[local-name()='Sightings']"
        conf_nodes = xml.search(xpath_exp)
	# Update XML to include the sightings
        xpath_exp="//*[local-name()='Indicator' and @id='#{ind.stix_id}']"
        ind_node = xml.xpath(xpath_exp).first
        if conf_nodes.present?
	  conf_nodes.first['sightings_count'] = total_sights
	  updated = true
	  conf_nodes.remove
	  ind_node.add_child(conf_nodes)
        else
          if ind_node.present?
            sightings_node = Nokogiri::XML::Element.new("indicator:Sightings", xml)
            sightings_node['sightings_count'] = total_sights
            ind_node.add_child(sightings_node)
            updated = true
          end
        end
      }
      
      if updated
        oi = XmlSaving.update_uploads_xml(xml.to_xml, uploaded_file.guid)
      end
      
      oi
    end

	end
end
