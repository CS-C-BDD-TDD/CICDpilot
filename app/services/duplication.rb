# The duplication service is only used for TS Systems.  This is to automatically deconflict classification differences.
# Right now this just makes a duplicate object that has an appended string to the end of the stix id specified in the settings.yml
class Duplication
	class << self
		# 6.4.2+
	  # Cybox objects now have there own markings.
	  # Each field can have their own markings.
	  def check_for_duplication(uploaded_file, obj, to_save, skip_validations)
	    if obj.respond_to?(:stix_id)
	      if obj.stix_id.nil?
	        obj.set_stix_id
	        obj.stix_id = obj.stix_id + Setting.READ_ONLY_EXT
	      end
	      # Check if the indicator exists
	      if obj.stix_id.include?(Setting.READ_ONLY_EXT)
	        old_obj = obj.class.find_by_stix_id(obj.stix_id.slice(0, obj.stix_id.length - Setting.READ_ONLY_EXT.length))
	      else
	        old_obj = obj.class.find_by_stix_id(obj.stix_id)
	      end
	    end

      if obj.respond_to?(:cybox_object_id)
	      if obj.cybox_object_id.nil?
	        obj.set_cybox_object_id
	        obj.cybox_object_id = obj.cybox_object_id + Setting.READ_ONLY_EXT
	      end
	      if obj.cybox_object_id.include?(Setting.READ_ONLY_EXT)
	        old_obj = obj.class.find_by_cybox_object_id(obj.cybox_object_id.slice(0, obj.cybox_object_id.length - Setting.READ_ONLY_EXT.length))
	      else
	        old_obj = obj.class.find_by_cybox_object_id(obj.cybox_object_id)
	      end
	    end

      if obj.respond_to?(:guid) && !obj.respond_to?(:stix_id) && !obj.respond_to?(:cybox_object_id)
        if obj.guid.nil?
          obj.set_guid
          obj.guid = obj.guid + Setting.READ_ONLY_EXT
        end
        if obj.guid.include?(Setting.READ_ONLY_EXT)
          old_obj = obj.class.find_by_guid(obj.guid.slice(0, obj.guid.length - Setting.READ_ONLY_EXT.length))
        else
          old_obj = obj.class.find_by_guid(obj.guid)
        end
      end
	    # new stuff for field level markings !!!! must change over to guid to find stix_markings !!!!
	    # Get the object level markings and the field level markings for the new object
	    new_stix_markings = to_save.select{|o| o.class == StixMarking && o.remote_object_id == obj.guid}
	    
	    # Create hash of classifications with remote object fields
	    new_classes = []

	    if !new_stix_markings.nil?
	      new_stix_markings.each do |sm|
	        if sm.isa_assertion_structure
	          new_classes << {'field' => sm.remote_object_field, 'classification' => sm.isa_assertion_structure.cs_classification}
	        end
	      end
	    end

	    if new_classes.blank?
	      # Means their was no associated markings, we will be applying defaults later in this case.
	      # Which means lets mimic defaults and see if theirs a problem
	      new_classes << {'field' => nil, 'classification' => 'U'}
	    end

	    # create a conflicting class boolean. If any of the attached markings have a different classification
	    # than the new obj than we have a problem and need to duplicate.  

	    conflicting_class = false
	    
	    # check old markings
      if !old_obj.nil?

        # use the portion marking to check against the object level marking, this is to also account for the case of an acs_set
        if old_obj.portion_marking.present?
          compare_class = new_classes.find { |e| e['field'] == nil }
          if compare_class.present? && compare_class['classification'] != old_obj.portion_marking
            conflicting_class = true
          end
        end

        # check the rest of the fields
        if old_obj.stix_markings.present?
          old_obj.stix_markings.each do |sm|
            if sm.remote_object_field != nil && sm.isa_assertion_structure.present?
              compare_class = new_classes.find { |e| e['field'] == sm.remote_object_field }
              if compare_class.present? && compare_class['classification'] != sm.isa_assertion_structure.cs_classification
                conflicting_class = true
              end
            end
          end
        end

      end

	    if conflicting_class
	      # Conflict in the classification. Delete the read only copy and resave
	      if !old_obj.nil?
	        old_obj.update_attribute(:read_only, true)
	      end
	      obj.read_only = true

	      to_save = self.create_dup_obj_links(obj, to_save, skip_validations)
	      # Uncomment the line below if you want to get rid of old links associated with the obj.
	      # self.destroy_old_objs(obj)
	    else 
	      # no conflict in the classification. Reset the stix_id and delete old record if present.
	      to_save = self.no_classification_conflict(uploaded_file, obj, to_save)

        if obj.respond_to?(:stix_id) && obj.stix_id.present? && obj.stix_id.include?(Setting.READ_ONLY_EXT)
          obj.read_only = true
        elsif obj.respond_to?(:cybox_object_id) && obj.cybox_object_id.present? && obj.cybox_object_id.include?(Setting.READ_ONLY_EXT)
          obj.read_only = true
        elsif obj.respond_to?(:guid) && obj.guid.present? && obj.guid.include?(Setting.READ_ONLY_EXT) && !obj.respond_to?(:cybox_object_id) && !obj.respond_to?(:stix_id)
          obj.read_only = true
        end
	    end

	    to_save
	  end

    # If we have a conflicting class we need to create a duplicate of the obj links because we delete them
    # on the other objects.
    def create_dup_obj_links(obj, to_save, skip_validations)
      # Dup stix id stuff, check the containing object if it does not contain the dup tag
      if obj.respond_to?(:stix_id) && !obj.stix_id.nil?
        # dup indicator things
        if obj.class == Indicator
          ip = to_save.select{ |o| o.class == IndicatorsPackage && o.stix_indicator_id == obj.stix_id}
          # Put the original back in also, because we want to keep the obj links.
          if ip.present?

            ip.each do |e|
              # Only if package was original and we deleted the links do we need to duplicate the indicators package
              if !e.stix_package_id.include?(Setting.READ_ONLY_EXT)
                normal_ip = IndicatorsPackage.new

                normal_ip.attribute_names.each do |a|
                  normal_ip[a] = e[a]
                end

                if e.stix_indicator_id.include?(Setting.READ_ONLY_EXT)
                  normal_ip.stix_indicator_id = e.stix_indicator_id.slice(0, e.stix_indicator_id.length - Setting.READ_ONLY_EXT.length)
                end
                
                # Tell it that its a upload and add it to the skip array
                normal_ip.is_upload = true
                skip_validations << normal_ip

                # add it to the to_save
                to_save << normal_ip
              end
            end
          end
        # Dup coa stuff
        elsif obj.class == CourseOfAction
          ip = to_save.select{ |o| o.class == PackagesCourseOfAction && o.course_of_action_id == obj.stix_id}
          # Put the original back in also, because we want to keep the obj links.
          if ip.present?
    
            ip.each do |e|
              # Only if package was original and we deleted the links do we need to duplicate the PackagesCourseOfAction
              if !e.stix_package_id.include?(Setting.READ_ONLY_EXT)
                normal_ip = PackagesCourseOfAction.new

                normal_ip.attribute_names.each do |a|
                  normal_ip[a] = e[a]
                end

                if e.course_of_action_id.include?(Setting.READ_ONLY_EXT)
                  normal_ip.course_of_action_id = e.course_of_action_id.slice(0, e.course_of_action_id.length - Setting.READ_ONLY_EXT.length)
                end
                
                # Tell it that its a upload and add it to the skip array
                normal_ip.is_upload = true
                skip_validations << normal_ip

                # add it to the to_save
                to_save << normal_ip
              end
            end
          end

          # Indicators Courses of Actions
          ip = to_save.select{ |o| o.class == IndicatorsCourseOfAction && o.course_of_action_id == obj.stix_id}
          # Put the original back in also, because we want to keep the obj links.
          if ip.present?

            ip.each do |e|
              # Only if we deleted the links do we need to duplicate the IndicatorsCourseOfAction
              if !e.stix_indicator_id.include?(Setting.READ_ONLY_EXT)
                normal_ip = IndicatorsCourseOfAction.new

                normal_ip.attribute_names.each do |a|
                  normal_ip[a] = e[a]
                end

                if e.course_of_action_id.include?(Setting.READ_ONLY_EXT)
                  normal_ip.course_of_action_id = e.course_of_action_id.slice(0, e.course_of_action_id.length - Setting.READ_ONLY_EXT.length)
                end
                
                # Tell it that its a upload and add it to the skip array
                normal_ip.is_upload = true
                skip_validations << normal_ip

                # add it to the to_save
                to_save << normal_ip
              end
            end
          end

          ip = to_save.select{ |o| o.class == ExploitTargetCourseOfAction && o.course_of_action_id == obj.stix_id}
          # Put the original back in also, because we want to keep the obj links.
          if ip.present?
    
            ip.each do |e|
              # Only if package was original and we deleted the links do we need to duplicate the ExploitTargetCourseOfAction
              if !e.stix_exploit_target_id.include?(Setting.READ_ONLY_EXT)
                normal_ip = ExploitTargetCourseOfAction.new

                normal_ip.attribute_names.each do |a|
                  normal_ip[a] = e[a]
                end

                if e.course_of_action_id.include?(Setting.READ_ONLY_EXT)
                  normal_ip.course_of_action_id = e.course_of_action_id.slice(0, e.course_of_action_id.length - Setting.READ_ONLY_EXT.length)
                end
                
                # Tell it that its a upload and add it to the skip array
                normal_ip.is_upload = true
                skip_validations << normal_ip

                # add it to the to_save
                to_save << normal_ip
              end
            end
          end
        # Dup exploit target stuff
        elsif obj.class == ExploitTarget
          ip = to_save.select{ |o| o.class == ExploitTargetPackage && o.stix_exploit_target_id == obj.stix_id}
          # Put the original back in also, because we want to keep the obj links.
          if ip.present?
    
            ip.each do |e|
              # Only if package was original and we deleted the links do we need to duplicate the ExploitTargetPackage
              if !e.stix_package_id.include?(Setting.READ_ONLY_EXT)
                normal_ip = ExploitTargetPackage.new

                normal_ip.attribute_names.each do |a|
                  normal_ip[a] = e[a]
                end

                if e.stix_exploit_target_id.include?(Setting.READ_ONLY_EXT)
                  normal_ip.stix_exploit_target_id = e.stix_exploit_target_id.slice(0, e.stix_exploit_target_id.length - Setting.READ_ONLY_EXT.length)
                end
                
                # Tell it that its a upload and add it to the skip array
                normal_ip.is_upload = true
                skip_validations << normal_ip

                # add it to the to_save
                to_save << normal_ip
              end
            end
          end

          # Now look for ttp exploit targets
          ip = to_save.select{ |o| o.class == TtpExploitTarget && o.stix_exploit_target_id == obj.stix_id}
          # Put the original back in also, because we want to keep the obj links.
          if ip.present?
    
            ip.each do |e|
              # Only if package was original and we deleted the links do we need to duplicate the TtpExploitTarget
              if !e.stix_ttp_id.include?(Setting.READ_ONLY_EXT)
                normal_ip = TtpExploitTarget.new

                normal_ip.attribute_names.each do |a|
                  normal_ip[a] = e[a]
                end

                if e.stix_exploit_target_id.include?(Setting.READ_ONLY_EXT)
                  normal_ip.stix_exploit_target_id = e.stix_exploit_target_id.slice(0, e.stix_exploit_target_id.length - Setting.READ_ONLY_EXT.length)
                end
                
                # Tell it that its a upload and add it to the skip array
                normal_ip.is_upload = true
                skip_validations << normal_ip

                # add it to the to_save
                to_save << normal_ip
              end
            end
          end
        # dup TTP stuff
        elsif obj.class == Ttp
          ip = to_save.select{ |o| o.class == TtpPackage && o.stix_ttp_id == obj.stix_id}
          # Put the original back in also, because we want to keep the obj links.
          if ip.present?
    
            ip.each do |e|
              # Only if package was original and we deleted the links do we need to duplicate the TtpPackage
              if !e.stix_package_id.include?(Setting.READ_ONLY_EXT)
                normal_ip = TtpPackage.new

                normal_ip.attribute_names.each do |a|
                  normal_ip[a] = e[a]
                end

                if e.stix_ttp_id.include?(Setting.READ_ONLY_EXT)
                  normal_ip.stix_ttp_id = e.stix_ttp_id.slice(0, e.stix_ttp_id.length - Setting.READ_ONLY_EXT.length)
                end
                
                # Tell it that its a upload and add it to the skip array
                normal_ip.is_upload = true
                skip_validations << normal_ip

                # add it to the to_save
                to_save << normal_ip
              end
            end
          end

          # Indicator TTPS
          ip = to_save.select{ |o| o.class == IndicatorTtp && o.stix_ttp_id == obj.stix_id}
          # Put the original back in also, because we want to keep the obj links.
          if ip.present?
    
            ip.each do |e|
              # Only if package was original and we deleted the links do we need to duplicate the IndicatorTtp
              if !e.stix_indicator_id.include?(Setting.READ_ONLY_EXT)
                normal_ip = IndicatorTtp.new

                normal_ip.attribute_names.each do |a|
                  normal_ip[a] = e[a]
                end

                if e.stix_ttp_id.include?(Setting.READ_ONLY_EXT)
                  normal_ip.stix_ttp_id = e.stix_ttp_id.slice(0, e.stix_ttp_id.length - Setting.READ_ONLY_EXT.length)
                end
                
                # Tell it that its a upload and add it to the skip array
                normal_ip.is_upload = true
                skip_validations << normal_ip

                # add it to the to_save
                to_save << normal_ip
              end
            end
          end
        # dup Attack Pattern stuff
        elsif obj.class == AttackPattern
          ip = to_save.select{ |o| o.class == TtpAttackPattern && o.stix_attack_pattern_id == obj.stix_id}
          # Put the original back in also, because we want to keep the obj links.
          if ip.present?
    
            ip.each do |e|
              # Only if package was original and we deleted the links do we need to duplicate the TtpAttackPattern
              if !e.stix_ttp_id.include?(Setting.READ_ONLY_EXT)
                normal_ip = TtpAttackPattern.new

                normal_ip.attribute_names.each do |a|
                  normal_ip[a] = e[a]
                end

                if e.stix_attack_pattern_id.include?(Setting.READ_ONLY_EXT)
                  normal_ip.stix_attack_pattern_id = e.stix_attack_pattern_id.slice(0, e.stix_attack_pattern_id.length - Setting.READ_ONLY_EXT.length)
                end
                
                # Tell it that its a upload and add it to the skip array
                normal_ip.is_upload = true
                skip_validations << normal_ip

                # add it to the to_save
                to_save << normal_ip
              end
            end
          end
        end
      # dup cybox object things
      elsif obj.respond_to?(:cybox_object_id) && !obj.cybox_object_id.nil?
        ip = to_save.select{ |o| o.class == Observable && o.remote_object_id == obj.cybox_object_id}
        # Put the original back in also, because we want to keep the obj links.
        if ip.present?
          ip.each do |e|
            # only if indicator was the original and delete the observables do we need to put it back.
            if !e.stix_indicator_id.include?(Setting.READ_ONLY_EXT)
              normal_ip = Observable.new

              normal_ip.attribute_names.each do |a|
                normal_ip[a] = e[a]
              end

              if e.remote_object_id.include?(Setting.READ_ONLY_EXT)
                normal_ip.remote_object_id = e.remote_object_id.slice(0, e.remote_object_id.length - Setting.READ_ONLY_EXT.length)
              end

              # Tell it that its a upload and add it to the skip array
              normal_ip.is_upload = true
              skip_validations << normal_ip

              # add it to the to_save
              to_save << normal_ip
            end
          end
        end

        ip = to_save.select{ |o| o.class == ParameterObservable && o.remote_object_id == obj.cybox_object_id}
        # Put the original back in also, because we want to keep the obj links.
        if ip.present?
          ip.each do |e|
            # only if indicator was the original and delete the parameter observables do we need to put it back.
            if !e.stix_course_of_action_id.include?(Setting.READ_ONLY_EXT)
              normal_ip = ParameterObservable.new

              normal_ip.attribute_names.each do |a|
                normal_ip[a] = e[a]
              end

              if e.remote_object_id.include?(Setting.READ_ONLY_EXT)
                normal_ip.remote_object_id = e.remote_object_id.slice(0, e.remote_object_id.length - Setting.READ_ONLY_EXT.length)
              end

              # Tell it that its a upload and add it to the skip array
              normal_ip.is_upload = true
              skip_validations << normal_ip

              # add it to the to_save
              to_save << normal_ip
            end
          end
        end
      # dup guid stuff
      elsif obj.respond_to?(:guid) && !obj.respond_to?(:cybox_object_id) && !obj.respond_to?(:stix_id)
        # dup vulnerabilities stuff
        if obj.class == Vulnerability
          ip = to_save.select{ |o| o.class == ExploitTargetVulnerability && o.vulnerability_guid == obj.guid}
          # Put the original back in also, because we want to keep the obj links.
          if ip.present?
    
            ip.each do |e|
              # Only if package was original and we deleted the links do we need to duplicate the ExploitTargetVulnerability
              if !e.stix_exploit_target_id.include?(Setting.READ_ONLY_EXT)
                normal_ip = ExploitTargetVulnerability.new

                normal_ip.attribute_names.each do |a|
                  normal_ip[a] = e[a]
                end

                if e.vulnerability_guid.include?(Setting.READ_ONLY_EXT)
                  normal_ip.vulnerability_guid = e.vulnerability_guid.slice(0, e.vulnerability_guid.length - Setting.READ_ONLY_EXT.length)
                end
                
                # Tell it that its a upload and add it to the skip array
                normal_ip.is_upload = true
                skip_validations << normal_ip

                # add it to the to_save
                to_save << normal_ip
              end
            end
          end
        end
      end

      to_save
    end

    # If the package/indicators was found to have no conflicting classifications
    # returns to_save object with original stix_id's
    def no_classification_conflict(uploaded_file, obj, to_save)
      if obj.respond_to?(:stix_id)
        original_id = obj.stix_id.include?(Setting.READ_ONLY_EXT) ? obj.stix_id.slice(0, obj.stix_id.length - Setting.READ_ONLY_EXT.length) : obj.stix_id
      end

      if obj.respond_to?(:cybox_object_id)
        original_id = obj.cybox_object_id.include?(Setting.READ_ONLY_EXT) ? obj.cybox_object_id.slice(0, obj.cybox_object_id.length - Setting.READ_ONLY_EXT.length) : obj.cybox_object_id
      end

      if obj.respond_to?(:guid) && obj.guid.present?
        original_guid = obj.guid.include?(Setting.READ_ONLY_EXT) ? obj.guid.slice(0, obj.guid.length - Setting.READ_ONLY_EXT.length) : obj.guid
      end

      to_save.each do |normal|
        if obj.respond_to?(:stix_id)
          if normal.respond_to?(:remote_object_id) && normal.remote_object_id == obj.stix_id
            if normal.class != StixMarking
              normal.remote_object_id = original_id
            end
          elsif normal.respond_to?(:stix_package_id) && normal.stix_package_id == obj.stix_id
            normal.stix_package_id = original_id
          elsif normal.respond_to?(:stix_indicator_id) && normal.stix_indicator_id == obj.stix_id
            normal.stix_indicator_id = original_id
          elsif normal.respond_to?(:course_of_action_id) && normal.course_of_action_id == obj.stix_id
            normal.course_of_action_id = original_id
          elsif normal.respond_to?(:stix_package_stix_id) && normal.stix_package_stix_id == obj.stix_id
            normal.stix_package_stix_id = original_id
          elsif normal.respond_to?(:stix_course_of_action_id) && normal.stix_course_of_action_id == obj.stix_id
            normal.stix_course_of_action_id = original_id
          elsif normal.respond_to?(:stix_exploit_target_id) && normal.stix_exploit_target_id == obj.stix_id
            normal.stix_exploit_target_id = original_id
          elsif normal.respond_to?(:stix_ttp_id) && normal.stix_ttp_id == obj.stix_id
            normal.stix_ttp_id = original_id
          elsif normal.respond_to?(:stix_attack_pattern_id) && normal.stix_attack_pattern_id == obj.stix_id
            normal.stix_attack_pattern_id = original_id
          end
        end
        
        if obj.respond_to?(:guid)
          if normal.respond_to?(:vulnerability_guid) && normal.vulnerability_guid == obj.guid
            normal.vulnerability_guid = original_guid
          elsif normal.respond_to?(:remote_src_object) && normal.remote_src_object_guid == obj.guid
            normal.remote_src_object_guid = original_guid
          elsif normal.respond_to?(:remote_dest_object) && normal.remote_dest_object_guid == obj.guid
            normal.remote_dest_object_guid = original_guid
          elsif normal.respond_to?(:target_guid) && normal.target_guid == obj.guid
            normal.target_guid = original_guid
          end
        end

        if obj.respond_to?(:cybox_object_id)
          if normal.respond_to?(:remote_object_id) && normal.remote_object_id == obj.cybox_object_id
            if normal.class != StixMarking
              normal.remote_object_id = original_id
            end
          elsif normal.respond_to?(:cybox_object_id) && normal.cybox_object_id == obj.cybox_object_id
            normal.cybox_object_id = original_id
          elsif normal.respond_to?(:cybox_file_id) && normal.cybox_file_id == obj.cybox_object_id
            normal.cybox_file_id = original_id
          elsif normal.respond_to?(:uri_object_id) && normal.uri_object_id == obj.cybox_object_id
            normal.uri_object_id = original_id
          elsif normal.respond_to?(:cybox_win_reg_key_id) && normal.cybox_win_reg_key_id == obj.cybox_object_id
            normal.cybox_win_reg_key_id = original_id
          end
        end

        if normal.class == StixMarking && normal.remote_object_id == obj.guid
          normal.remote_object_id = original_guid
          # set stix_markings stix_id back to normal as well
          normal.stix_id = normal.stix_id.include?(Setting.READ_ONLY_EXT) ? normal.stix_id.slice(0, normal.stix_id.length - Setting.READ_ONLY_EXT.length) : normal.stix_id
          normal.guid = normal.guid.include?(Setting.READ_ONLY_EXT) ? normal.guid.slice(0, normal.guid.length - Setting.READ_ONLY_EXT.length) : normal.guid

          # relink isa markings/assertions/tlp/simple
          if normal.isa_assertion_structure
            normal.isa_assertion_structure.stix_marking_id = normal.stix_id

            # reset stix_id/guid to normal
            normal.isa_assertion_structure.stix_id = normal.isa_assertion_structure.stix_id.include?(Setting.READ_ONLY_EXT) ? normal.isa_assertion_structure.stix_id.slice(0, normal.isa_assertion_structure.stix_id.length - Setting.READ_ONLY_EXT.length) : normal.isa_assertion_structure.stix_id
            normal.isa_assertion_structure.guid = normal.isa_assertion_structure.guid.include?(Setting.READ_ONLY_EXT) ? normal.isa_assertion_structure.guid.slice(0, normal.isa_assertion_structure.guid.length - Setting.READ_ONLY_EXT.length) : normal.isa_assertion_structure.guid

            # relink further sharing/isa privs
            if normal.isa_assertion_structure.isa_privs
              normal.isa_assertion_structure.isa_privs.each do |ip|
                ip.isa_assertion_structure_guid = normal.isa_assertion_structure.guid
              end
            end

            if normal.isa_assertion_structure.further_sharings
              normal.isa_assertion_structure.further_sharings.each do |fs|
                fs.isa_assertion_structure_guid = normal.isa_assertion_structure.guid
              end
            end
          end
          if normal.isa_marking_structure
            normal.isa_marking_structure.stix_marking_id = normal.stix_id

            # reset stix_id/guid to normal
            normal.isa_marking_structure.stix_id = normal.isa_marking_structure.stix_id.include?(Setting.READ_ONLY_EXT) ? normal.isa_marking_structure.stix_id.slice(0, normal.isa_marking_structure.stix_id.length - Setting.READ_ONLY_EXT.length) : normal.isa_marking_structure.stix_id
            normal.isa_marking_structure.guid = normal.isa_marking_structure.guid.include?(Setting.READ_ONLY_EXT) ? normal.isa_marking_structure.guid.slice(0, normal.isa_marking_structure.guid.length - Setting.READ_ONLY_EXT.length) : normal.isa_marking_structure.guid
          end
          if normal.tlp_marking_structure
            normal.tlp_marking_structure.stix_marking_id = normal.stix_id

            # reset stix_id/guid to normal
            normal.tlp_marking_structure.stix_id = normal.tlp_marking_structure.stix_id.slice(0, normal.tlp_marking_structure.stix_id.length - Setting.READ_ONLY_EXT.length)
            normal.tlp_marking_structure.guid = normal.tlp_marking_structure.guid.slice(0, normal.tlp_marking_structure.guid.length - Setting.READ_ONLY_EXT.length)
            normal.tlp_marking_structure.stix_id = normal.tlp_marking_structure.stix_id.include?(Setting.READ_ONLY_EXT) ? normal.tlp_marking_structure.stix_id.slice(0, normal.tlp_marking_structure.stix_id.length - Setting.READ_ONLY_EXT.length) : normal.tlp_marking_structure.stix_id
            normal.tlp_marking_structure.guid = normal.tlp_marking_structure.guid.include?(Setting.READ_ONLY_EXT) ? normal.tlp_marking_structure.guid.slice(0, normal.tlp_marking_structure.guid.length - Setting.READ_ONLY_EXT.length) : normal.tlp_marking_structure.guid
          end
          if normal.ais_consent_marking_structure
            normal.ais_consent_marking_structure.stix_marking_id = normal.stix_id

            # reset stix_id/guid to normal
            normal.ais_consent_marking_structure.stix_id = normal.ais_consent_marking_structure.stix_id.slice(0, normal.ais_consent_marking_structure.stix_id.length - Setting.READ_ONLY_EXT.length)
            normal.ais_consent_marking_structure.guid = normal.ais_consent_marking_structure.guid.slice(0, normal.ais_consent_marking_structure.guid.length - Setting.READ_ONLY_EXT.length)
            normal.ais_consent_marking_structure.stix_id = normal.ais_consent_marking_structure.stix_id.include?(Setting.READ_ONLY_EXT) ? normal.ais_consent_marking_structure.stix_id.slice(0, normal.ais_consent_marking_structure.stix_id.length - Setting.READ_ONLY_EXT.length) : normal.ais_consent_marking_structure.stix_id
            normal.ais_consent_marking_structure.guid = normal.ais_consent_marking_structure.guid.include?(Setting.READ_ONLY_EXT) ? normal.ais_consent_marking_structure.guid.slice(0, normal.ais_consent_marking_structure.guid.length - Setting.READ_ONLY_EXT.length) : normal.ais_consent_marking_structure.guid
          end
        end
      end

      if obj.respond_to?(:stix_id)
        obj.stix_id = original_id
      end
      
      if obj.respond_to?(:cybox_object_id)
        # set all the observables/parameter observables back to normal
        obj_observables = to_save.select {|d| d.respond_to?(:remote_object_id) && (d.remote_object_id == obj.cybox_object_id || d.remote_object_id == obj.cybox_object_id + Setting.READ_ONLY_EXT)}
        # you must get observables before resetting id
        # reset the id
        obj.cybox_object_id = obj.cybox_object_id && obj.cybox_object_id.include?(Setting.READ_ONLY_EXT) ? obj.cybox_object_id.slice(0, obj.cybox_object_id.length - Setting.READ_ONLY_EXT.length) : obj.cybox_object_id
        if obj_observables.present?
          obj_observables.each do |o|
            o.cybox_object_id = o.cybox_object_id && o.cybox_object_id.include?(Setting.READ_ONLY_EXT) ? o.cybox_object_id.slice(0, o.cybox_object_id.length - Setting.READ_ONLY_EXT.length) : o.cybox_object_id
            o.remote_object_id = original_id
          end
        end

        old_cybox = to_save.select {|o| o.respond_to?(:cybox_object_id) && o.cybox_object_id == obj.cybox_object_id }

        # spoof the swap if needed function so we can use it than set the read only back to true
        old_cybox[0] = IngestUtilities.spoof_swap(uploaded_file, old_cybox[0], old_cybox[0].read_only, uploaded_file.read_only, uploaded_file.overwrite, to_save)
        
        # We need both in them because we have a method that removes the one without an id later.
        if old_cybox[0].id != nil
          unless to_save.include?(old_cybox[0])
            to_save << old_cybox[0]
          end
        end

        to_save = self.destroy_old_objs(old_cybox[0], to_save)
      end

      if obj.respond_to?(:guid) && obj.guid.present?
        obj.guid = original_guid
      end

      to_save = self.destroy_old_objs(obj, to_save)

      to_save
    end

    # Destroys old instances of duplicated items.
    def destroy_old_objs(obj, to_save)
      if obj.respond_to?(:stix_id) && !obj.stix_id.nil?
        obj_to_destroy = obj.class.find_by_stix_id(obj.stix_id)
        if obj_to_destroy.present?
          # Get rid of old indicator things
          obj_to_destroy.stix_markings.destroy_all
          if obj.class == Indicator
            obj_to_destroy.observables.destroy_all
            obj_to_destroy.indicators_course_of_actions.destroy_all
            obj_to_destroy.confidences.destroy_all
            obj_to_destroy.indicator_ttps.destroy_all
            obj_to_destroy.sightings.destroy_all
          # get rid of old stix package things
          elsif obj.class == StixPackage
            obj_to_destroy.indicators_packages.destroy_all
            obj_to_destroy.exploit_target_packages.destroy_all
            obj_to_destroy.packages_course_of_actions.destroy_all
            obj_to_destroy.contributing_sources.destroy_all
            obj_to_destroy.ttp_packages.destroy_all
          # get rid of old COA things
          elsif obj.class == CourseOfAction
            obj_to_destroy.parameter_observables.destroy_all
          # Exploit Targets 
          elsif obj.class == ExploitTarget
            obj_to_destroy.exploit_target_vulnerabilities.destroy_all
            obj_to_destroy.exploit_target_course_of_actions.destroy_all
          # Vulnerabilities dont need anything because we just destroy stix markings
          elsif obj.class == Vulnerability
          elsif obj.class == Ttp
            obj_to_destroy.ttp_attack_patterns.destroy_all
            obj_to_destroy.ttp_exploit_targets.destroy_all
          # Attack Patterns dont need anything because we just destroy stix markings
          elsif obj.class == AttackPattern
          end
        end
      # Get rid of old cybox object things
      elsif obj.respond_to?(:cybox_object_id) && !obj.cybox_object_id.nil?
        obj_to_destroy = obj.class.find_by_cybox_object_id(obj.cybox_object_id)
        if obj_to_destroy.present?
          obj_to_destroy.stix_markings.destroy_all
        end
      end

      if obj_to_destroy.present? && obj.id != obj_to_destroy.id
        to_save -= [obj_to_destroy]
        obj_to_destroy.destroy
      end

      to_save
    end

	end
end
