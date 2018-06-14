# The Ingest service's main purpose is for ingesting Stix XML that is uploaded into the system and turning it into
# Objects that the system recognizes.  This service works with the duplication service when resolving conflicts in classification.
class Ingest
  class << self
    # Stores STIX data into the database. The arguments are a list of parsed
    # STIX objects and the user ID behind the data ingestion.
    def store_stix_data(uploaded_file, lst, current_user_guid, options = {})
      user = User.find_by_guid(current_user_guid)
            
      to_save = []
      skip_validations = []
      # Define here so it can be used outside of the loop
      do_not_create_package = nil
      do_not_create_package = self.ingest_stix_package(uploaded_file, skip_validations, lst, user, to_save)
      # Duplication
      if uploaded_file.read_only || (Setting.CLASSIFICATION == true && uploaded_file.overwrite)
        to_save.each do |x|
          next if x.blank?
          if StixMarking::VALID_CLASSES.include?(x.class.to_s)
            if x.class == Observable
              next
            end
            to_save = Duplication.check_for_duplication(uploaded_file, x, to_save, skip_validations)
          end
        end
      end
      
      
      # All validations that we want to happen on upload
      to_save = IngestUtilities.ingest_validations(to_save)

      if (uploaded_file.validate_only || (uploaded_file.human_review_needed && (uploaded_file.human_review.blank? || (uploaded_file.human_review.present? && uploaded_file.human_review.status != "A")))) && uploaded_file.original_inputs.count > 1
        stix_markings = []
        contributing_sources = []
        package = nil
        to_save.each do |x|
          contributing_sources << x if x.class == ContributingSource
          stix_markings << x if x.class == StixMarking
          package = x if x.class == StixPackage
        end
        has_isa_already = false
        stix_marking = nil
        stix_markings.each do |sm|
          has_isa_already = true if sm.isa_assertion_structure.present?
          stix_marking = sm if sm.ais_consent_marking_structure.present?
        end
        if stix_marking.present? && package.present? && !has_isa_already
          stix_marking.create_isa_from_ais(package,uploaded_file.original_inputs.where(input_sub_category: OriginalInput::XML_SANITIZED).first)
        end
        if contributing_sources.present? && package.present?
          package.uploaded_file = uploaded_file
          package.contributing_sources.first.fix_in_original_input(package,uploaded_file.original_inputs.where(input_sub_category: OriginalInput::XML_SANITIZED).first)
        end
      elsif !uploaded_file.validate_only && uploaded_file.status != ActionStatus::FAILED
        #::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)
        isa_check = []
        stix_markings = []
        contributing_sources = []
        package = nil
        to_save = IngestUtilities.remove_duplicate_observables(to_save)
        to_save.each do |x|
          begin
            if x.class == StixMarking
              stix_markings << x
              next
            end
            contributing_sources << x if x.class == ContributingSource
            package = x if x.class == StixPackage
            
            if x.class == Indicator || x.class == StixPackage
              UploadLogger.info("[Upload][save] Saving  Indicator block #{x.class.to_s}")
              x.set_stix_id
              x.set_guid
              if x.class == Indicator 
                x.is_ais = is_ais_provider_user?(user)
                
              end
              x.save!(validate: false)
              if do_not_create_package
                uploaded_file.indicators << x
              end
            elsif x.class.included_modules.include?(Cyboxable)
              UploadLogger.info("[Upload][save] Saving Cyboxable Links #{x.class.to_s}")
              # If the class includes any links that haven't been saved, save the links first
              # This resolves an issue where the join table was being populated with nil as
              # the link_id
              if x.respond_to?(:links)
                x.links.each { |link|
                  link.save!(validate: false) if link.id.nil?
                }
              end
              x.set_cybox_object_id
              x.set_guid
              x.save!(validate: false)
            else
              UploadLogger.info("[Upload][save] else block #{x.class.to_s}")
              x.save
            end
          rescue Exception => e
            if e.kind_of?(Array)
              IngestUtilities.add_error(uploaded_file, "#{e.message.first} (#{x.class})")
            else
              IngestUtilities.add_error(uploaded_file, "#{e.message} (#{x.class})")
            end
            ExceptionLogger.debug("exception: #{e}, message: #{e.message}, backtrace: #{e.backtrace}")
          end
          if x.class.respond_to?(:apply_default_policy_if_needed)
            isa_check << x
          end
        end
        
        skip_validations.each {|x| x.is_upload = false}
        consent_marking = nil
        acs_markings = []

        stix_markings.each do |sm|
          if sm.ais_consent_marking_structure.present?
            consent_marking = sm
          elsif sm.isa_assertion_structure.present?
            begin
              UploadLogger.info("[Upload][save] Saving #{sm.class.to_s}")
              sm.save!
              object = sm.remote_object
              if object.respond_to?(:set_portion_marking)
                object.reload
                object.set_portion_marking
              end
            rescue Exception => e
              if e.kind_of?(Array)
                IngestUtilities.add_error(uploaded_file, "#{e.message.first} (#{sm.class})")
              else
                IngestUtilities.add_error(uploaded_file, "#{e.message} (#{sm.class})")
              end
              ExceptionLogger.debug("exception: #{e}, message: #{e.message}, backtrace: #{e.backtrace}")
            end
          else
            sm.save!
          end
          if sm.fd_ais? && sm.remote_object.present? &&
              sm.remote_object.respond_to?(:update_is_ais_on_indicators)
            sm.remote_object.update_is_ais_on_indicators
          end
        end
        
        if consent_marking.present?
          begin
            UploadLogger.info("[Upload][save] Saving #{consent_marking.class.to_s}")
            consent_marking.save!
          rescue Exception => e
            if e.kind_of?(Array)
              IngestUtilities.add_error(uploaded_file, "#{e.message.first} (#{consent_marking.class})")
            else
              IngestUtilities.add_error(uploaded_file, "#{e.message} (#{consent_marking.class})")
            end
            ExceptionLogger.debug("exception: #{e}, message: #{e.message}, backtrace: #{e.backtrace}")
          end
        end
        
        if contributing_sources.present? && package.present?
          package.uploaded_file = uploaded_file
          package.contributing_sources.first.fix_in_original_input(package)
        end
        
        # Add object to the PendingMarkings table to be processed in the
        # background
        isa_check.each {|x| 
          PendingMarking.create(remote_object_type: x.class.name, remote_object_guid: x.guid)
        }
        
        #::Sunspot.session = ::Sunspot.session.original_session
        #to_save.each do |x|
        #  begin
        #    x.index if x.respond_to?(:index)
        #  rescue Exception => e
        #    if e.kind_of?(Array)
        #      IngestUtilities.add_error(uploaded_file, "#{e.message.first} (#{e.class})")
        #    else
        #      IngestUtilities.add_error(uploaded_file, "#{e.message} (#{e.class})")
        #    end
        #    ExceptionLogger.debug("exception: #{e}, message: #{e.message}, backtrace: #{e.backtrace}")
        #  end
        #end

        # Need to reload package to make sure we have indicators for these autoenrichments
        package.reload
        IngestUtilities.update_confidences(package, uploaded_file)
        IngestUtilities.update_sightings(package, uploaded_file)
          
        original_input = uploaded_file.original_inputs.transfer
        if original_input.blank?
          ReplicationUtilities.log_non_replication('Original Input XML nil or empty.',
                                                   '[nil]', self.class.to_s,
                                                   __LINE__)
          return true
        end
        # don't disseminate the file if avp validation failed.
        # don't worry about avp valid status if human review since that means it came from flare
        if package.blank?
          ReplicationUtilities.log_non_replication('STIX Package nil or empty.',
                                                   original_input.id,
                                                   self.class.to_s, __LINE__)
          return true
        end
        # Replications of repl_type "publish" only exist on CIAP so we won't
        # be replicating the original input from here unless this is CIAP.
        return true unless AppUtilities.is_ciap?
        # CISCP files wile always be replicated from CIAP to ECIS.
        unless package.is_ciscp
          # Only replicate files flagged to replicate.
          unless uploaded_file.replicate
            ReplicationUtilities.log_non_replication('Uploaded File replicate flag is set to false.',
                                                     original_input.id,
                                                     self.class.to_s, __LINE__)
            return true
          end
          # Only replicate files with both a submission mechanism and a
          # consent marking.
          if package.submission_mechanism.blank?
            ReplicationUtilities.log_non_replication('Submission Mechanism not present.',
                                                     original_input.id,
                                                     self.class.to_s, __LINE__)
            return true
          end
          if consent_marking.blank?
            ReplicationUtilities.log_non_replication('Consent Marking not present.',
                                                     original_input.id,
                                                     self.class.to_s, __LINE__)
            return true
          end
          # If Setting.FLARE_AVP_PATH is undefined, AVP validation is not
          # used to determination whether a file will replicate from CIAP to
          # ECIS. Files needing HR also ignore AVP validation before HR
          # approval. Files that failed AVP validation are not replicated
          # from CIAP to ECIS.
          unless Setting.FLARE_AVP_PATH.blank? ||
              uploaded_file.avp_valid ||
              uploaded_file.avp_validation == false ||
              uploaded_file.human_review_needed
            ReplicationUtilities.log_non_replication('Failed AVP validation.',
                                                     original_input.id,
                                                     self.class.to_s, __LINE__)
            return true
          end
          # Files with a nil input_sub_category or an input_sub_category of
          # OriginalInput::XML_HUMAN_REVIEW_PENDING will be replicated from
          # CIAP to ECIS for either the legacy or DMS 1b+ architecture.
          unless original_input.input_sub_category.nil? ||
              original_input.input_sub_category ==
                  OriginalInput::XML_HUMAN_REVIEW_PENDING
            # In the legacy architecture, files with an input_sub_category
            # populated with a value other than
            # OriginalInput::XML_HUMAN_REVIEW_PENDING will not be replicated
            # from CIAP to ECIS. A file with a nil input_sub_category will be
            # replicated because ECIS will perform the sanitization in the
            # legacy architecture.
            if AppUtilities.is_ciap_legacy_arch?
              ReplicationUtilities.log_non_replication("Input Sub-Category is \"#{original_input.input_sub_category}.\"",
                                                       original_input.id,
                                                       self.class.to_s, __LINE__)
              return true
            end
            # In the DMS 1b+ architecture, files with an input_sub_category of
            # OriginalInput::XML_UNICORN will also be replicated from CIAP to
            # ECIS since this determination can now be made on CIAP due to
            # the move of sanitization to CIAP.
            if AppUtilities.is_ciap_dms_1b_or_1c_arch? &&
                original_input.input_sub_category != OriginalInput::XML_UNICORN
              ReplicationUtilities.log_non_replication("Input Sub-Category is \"#{original_input.input_sub_category}.\"",
                                                       original_input.id,
                                                       self.class.to_s, __LINE__)
              return true
            end
          end
        end

        if AppUtilities.is_ciap_dms_1c_arch? && AppUtilities.is_amqp_sender?
          if Setting.DISSEMINATION_TRANSFORMING_ENABLED
            ReplicationUtilities.disseminate_xml(original_input.utf8_raw_content,
                                                 original_input.id, 'publish',
                                                 original_input.dissemination_labels)
          else
            ReplicationUtilities.replicate_xml(original_input.utf8_raw_content,
                                             original_input.id,
                                             'publish', nil,
                                             OriginalInput::XML_DISSEMINATION_TRANSFER, uploaded_file.final,
                                             original_input.dissemination_labels)
          end
        elsif AppUtilities.is_ciap_dms_1b_arch? && AppUtilities.is_amqp_sender?
          ReplicationUtilities.replicate_xml(original_input.utf8_raw_content,
                                             original_input.id,
                                             'publish', nil,
                                             OriginalInput::XML_DISSEMINATION_TRANSFER, uploaded_file.final,
                                             original_input.dissemination_labels)
        else
          # For the CIAP legacy architecture and for the CIAP DMS 1b+
          # architecture when AMQP sending is not enabled for either testing
          # or another non-production purpose, the file will be replicated via
          # the following method call.
          ReplicationUtilities.replicate_xml(original_input.utf8_raw_content,
                                             original_input.id,
                                             'publish', nil, nil, uploaded_file.final)
        end
      end
      true
    rescue StandardError => e
      if e.kind_of?(Array)
        IngestUtilities.add_error(uploaded_file, "#{e.message.first} (#{e.class})")
      else
        IngestUtilities.add_error(uploaded_file, "#{e.message} (#{e.class})")
      end
      ExceptionLogger.debug("exception: #{e}, message: #{e.message}, backtrace: #{e.backtrace}")
      false
    end
    # returns do_not_save_package boolean used to determine if package should be created or not in zip uploads
    def ingest_stix_package(uploaded_file, skip_validations, lst, user, to_save)
      do_not_create_package = nil
      lst.each do |rpt|
        obs_wo_inds = rpt['observables_without_indicators']
        pkg = StixPackage.ingest(uploaded_file, rpt, user)           # Package (Top-Level)
        return if pkg.blank?
        if pkg.short_description == '##--DO-NOT-CREATE-PACKAGE--##'
          do_not_create_package = true
          pkg = {}  # Instead of setting to nil, create a Hash to serve as a
          # dummy container for passing uploaded_kill_chains. Check the class
          # type and/or the do_not_create_package flag as appropriate to
          # ensure that operations proceed approprately below.
        else
          pkg.uploaded_file_id = uploaded_file.guid
          pkg.is_upload = true
          skip_validations << pkg
          to_save << pkg
        end
        if rpt.kill_chains.present?
          uploaded_kill_chains = []
          rpt.kill_chains.each do |i|
            k = KillChain.ingest(uploaded_file, i)              # KillChain -------
            unless k.nil?
              # Temporarily store kill chains for later use
              uploaded_kill_chains << k
              to_save << k
            end
          end
          if do_not_create_package
            # Add uploaded_kill_chains to the dummy package hash.
            pkg[:uploaded_kill_chains] = uploaded_kill_chains
          else
            # Add uploaded_kill_chains to the StixPackage via the accessor.
            pkg.uploaded_kill_chains = uploaded_kill_chains
          end
        end
        # Contributing Source, MUST BE BEFORE STIX MARKING
        if rpt.contributing_sources.present? && !do_not_create_package
          # If the package was not created because of the
          # do_not_create_package flag, skip ingestion of contributing
          # sources since the ingest method will return immediately if the
          # pkg parameter is nil.
          rpt.contributing_sources.each do |i|
            s = ContributingSource.ingest(uploaded_file,i,pkg)
            unless s.nil?
              to_save << s
              pkg.contributing_sources << s
            end
          end
        end
        if rpt.markings.present? && !do_not_create_package
          # If the package was not created because of the
          # do_not_create_package flag, skip ingestion of markings since the
          # ingest method will return immediately if the pkg parameter is nil.
          rpt.markings.each do |i|
            m = StixMarking.ingest(uploaded_file, i, pkg)            # Marking ---------
            if m.present? && m.valid?
              to_save << m
            else
              IngestUtilities.add_error(uploaded_file, "#{m.errors.full_messages.first}")
            end
          end
        end
        # Make sure the associated STIX_ID gets stored, so everything is linked
        if pkg.present? && pkg.class == StixPackage
          oi = OriginalInput.where("uploaded_file_id = ? and input_category <> 'SOURCE'", uploaded_file.guid).first
          oi.update_attribute(:remote_object_id, pkg.stix_id)
          oi.update_attribute(:remote_object_type, pkg.class.to_s)
        end
              # course_of_actions
        if rpt.course_of_actions.present?
          rpt.course_of_actions.each do |c|
            self.ingest_course_of_action(uploaded_file, skip_validations, c, user, pkg, to_save)
          end # --- course_of_actions.each
        end # --- course_of_actions.present?
        # exploit_targets
        if rpt.exploit_targets.present?
          rpt.exploit_targets.each do |e|
            self.ingest_exploit_target(uploaded_file, skip_validations, e, user, pkg, to_save)
          end
        end
        # ttps
        if rpt.ttps.present?
          rpt.ttps.each do |t|
            self.ingest_ttp(uploaded_file, skip_validations, t, user, pkg, to_save)
          end
        end
        if rpt.indicators.present?
          all_indicators = []
          rpt.indicators.each do |i|
            self.ingest_stix_indicator(uploaded_file, skip_validations, i, user, pkg, to_save)      # Indicator
          end # --- Indicators.each
          # Get the list of indicators
          to_save.each do |e|
            all_indicators << e if e.class == Indicator
          end
          # Now that we have all of the indicators created, we need to
          # see if there are any related indicators to match up
          begin
            rpt.indicators.each do |i|
              if self.read_only || (Setting.CLASSIFICATION == true && self.overwrite)
                next unless to_save.select {|x| x.class == Indicator}.collect(&:stix_id).include?(i.stix_id + Setting.READ_ONLY_EXT)
              else
                next unless to_save.select {|x| x.class == Indicator}.collect(&:stix_id).include?(i.stix_id)
              end
              if i.related_indicators.present?
                i.related_indicators.each do |x|
                  if self.read_only || (Setting.CLASSIFICATION == true && self.overwrite)
                    ind = all_indicators[all_indicators.find_index{|ai| ai.stix_id == i.stix_id + Setting.READ_ONLY_EXT}]
                    rind = all_indicators[all_indicators.find_index{|ai| ai.stix_id == x.indicator + Setting.READ_ONLY_EXT}]
                  else
                    ind = all_indicators[all_indicators.find_index{|ai| ai.stix_id == i.stix_id}]
                    rind = all_indicators[all_indicators.find_index{|ai| ai.stix_id == x.indicator}]
                  end
                  # Relationships have more moving pieces to deal with, so the "parent"
                  # we're passing in is really a hash.
                  r = Relationship.ingest(uploaded_file, x, { parent_indicator: ind,
                                         child_indicator: rind })
                  to_save << r unless r.nil?
                end
              end
            end
          rescue
            # Continue onward if the relationships don't load
          end
        end # --- Indicators.present?
        if obs_wo_inds.any?
          obs_wo_inds.each do |observ|
            self.ingest_observable(uploaded_file, skip_validations, observ, "Observable", pkg, to_save)
          end # --- Observable.present?
        end
      end # --- Packages.each
      do_not_create_package
    end
    def ingest_stix_indicator(uploaded_file, skip_validations, i, user, pkg, to_save)
      
      if i.is_composite
        IngestUtilities.add_warning(uploaded_file,"Indicator: Composite indicators not supported " +
            "- loading without composite details")
        return
      end
      ind = Indicator.ingest(uploaded_file, i, user)          # Indicator -------
      return if ind.blank?
      ind.is_upload = true

      ind.is_ciscp = true if pkg.is_ciscp
      ind.is_mifr = true if pkg.is_mifr
      
      skip_validations << ind
      return ind unless ind.new_record? || uploaded_file.overwrite || uploaded_file.read_only
      to_save << ind
      if i.markings.present?
        i.markings.each do |x|
          m = StixMarking.ingest(uploaded_file, x, ind)       # Marking ---------
          if m.present?
            to_save << m
          end
        end
      end
      if pkg.present? && pkg.class.to_s.match(/Package/)
        ip = IndicatorsPackage.ingest(uploaded_file, ind, pkg) # IndicatorsPackage
        if ip.present?
          ip.is_upload = true
          skip_validations << ip
          to_save << ip
        end
      end
      # Suggested COA's
      if i.suggested_coas.present?
        i.suggested_coas.each do |coa|
          scoa = IndicatorsCourseOfAction.ingest(uploaded_file, coa, ind)
          next if scoa.blank?
          scoa.is_upload = true
          skip_validations << scoa
          to_save << scoa
        end
      end
      # indicated ttp
      if i.indicated_ttps.present?
        i.indicated_ttps.each do |ttp|
          itp = IndicatorTtp.ingest(uploaded_file, ttp, ind)
          next if itp.blank?
          itp.is_upload = true
          skip_validations << itp
          to_save << itp
        end
      end
      if i.sightings.present?
        i.sightings.each do |s|
          st = Sighting.ingest(uploaded_file, s, ind)         # Sighting --------
          next if st.blank?
          to_save << st
        end
      end
      if i.kill_chain_phases.present?
        i.kill_chain_phases.each do |s|
          kc = KillChainRef.ingest(uploaded_file, s, pkg)    # Kill Chain Ref --
          unless kc.nil?
            # Connect the Indicator to the Ref
            kc.remote_object_id = i.stix_id
            # Destroy old kill chains attached to indicator.
            old_kcs = KillChainRef.where(remote_object_id: i.stix_id)
            if old_kcs.present? && !old_kcs.blank?
              old_kcs.destroy_all
            end
            to_save << kc
          end
        end
      end
      if i.observable.present?                       # Observable ------
        self.ingest_observable(uploaded_file, skip_validations, i.observable, "Observable", ind, to_save)
      end # --- Observable.present?
      ind
    end
    # Courses of Action -------
    def ingest_course_of_action(uploaded_file, skip_validations, c, user, pkg, to_save)
      
      # First you ingest the COA
      coa = CourseOfAction.ingest(uploaded_file, c, user)
      return if coa.blank?
      coa.is_upload = true
      coa.is_ciscp = true if pkg.is_ciscp
      coa.is_mifr = true if pkg.is_mifr
      skip_validations << coa
      # Only continue if we need to overwrite or its a new record
      return coa unless coa.new_record? || uploaded_file.overwrite || uploaded_file.read_only
      # Make sure it goes into our to_save array
      to_save << coa
      # Marking ---------
      if c.markings.present?
        c.markings.each do |x|
          m = StixMarking.ingest(uploaded_file, x, coa)
          if m.present?
            to_save << m
          end
        end
      end
      # package coas
      if pkg.present? && pkg.class.to_s.match(/Package/)
        ip = PackagesCourseOfAction.ingest(uploaded_file, coa, pkg)
        if ip.present?
          ip.is_upload = true
          skip_validations << ip
          to_save << ip
        end
      end
      # ind coas present?
      # parameter observables present?
      if c.parameter_observables.present?
        c.parameter_observables.each do |pobs|
          self.ingest_observable(uploaded_file, skip_validations, pobs, "ParameterObservable", coa, to_save)
        end
      end
      coa
    end
    # Exploit Targets -------
    def ingest_exploit_target(uploaded_file, skip_validations, e, user, pkg, to_save)
      
      # First you ingest the COA
      exta = ExploitTarget.ingest(uploaded_file, e, user)
      return if exta.blank?
      exta.is_upload = true
      exta.is_ciscp = true if pkg.is_ciscp
      exta.is_mifr = true if pkg.is_mifr

      skip_validations << exta
      # Only continue if we need to overwrite or its a new record
      return exta unless exta.new_record? || uploaded_file.overwrite || uploaded_file.read_only
      # Make sure it goes into our to_save array
      to_save << exta
      # Marking ---------
      if e.markings.present?
        e.markings.each do |x|
          m = StixMarking.ingest(uploaded_file, x, exta)
          if m.present?
            to_save << m
          end
        end
      end
      # package ets
      if pkg.present? && pkg.class.to_s.match(/Package/)
        etp = ExploitTargetPackage.ingest(uploaded_file, exta, pkg)
        if etp.present?
          etp.is_upload = true
          skip_validations << etp
          to_save << etp
        end
      end
      # Potential COAs
      if e.potential_coas.present?
        e.potential_coas.each do |pcoa|
          etcoa = ExploitTargetCourseOfAction.ingest(uploaded_file, pcoa, exta)
          next if etcoa.blank?
          etcoa.is_upload = true
          skip_validations << etcoa
          to_save << etcoa
        end
      end
      # vulnerabilities present?
      if e.vulnerabilities.present?
        e.vulnerabilities.each do |v|
          vul = self.ingest_vulnerability(uploaded_file, skip_validations, v, user, exta, to_save)
          next if vul.blank?
          etv = ExploitTargetVulnerability.ingest(uploaded_file, vul, exta)
          if etv.present?
            etv.is_upload = true
            skip_validations << etv
            to_save << etv
          end
        end
      end
      exta
    end
    # Vulnerabilities -------
    def ingest_vulnerability(uploaded_file, skip_validations, v, user, pkg, to_save)
      # First you ingest the Vulnerability
      vul = Vulnerability.ingest(uploaded_file, v, user)
      return if vul.blank?
      vul.is_upload = true
      vul.is_ciscp = true if pkg.is_ciscp
      vul.is_mifr = true if pkg.is_mifr
      skip_validations << vul
      # Only continue if we need to overwrite or its a new record
      return vul unless vul.new_record? || uploaded_file.overwrite || uploaded_file.read_only
      # Make sure it goes into our to_save array
      to_save << vul
      # Marking ---------
      if v.markings.present?
        v.markings.each do |x|
          m = StixMarking.ingest(uploaded_file, x, vul)
          if m.present?
            to_save << m
          end
        end
      end
      vul
    end
    # Ttps ------
    def ingest_ttp(uploaded_file, skip_validations, t, user, pkg, to_save)
      # First you ingest the COA
      ttp = Ttp.ingest(uploaded_file, t, user)
      return if ttp.blank?
      ttp.is_upload = true
      ttp.is_ciscp = true if pkg.is_ciscp
      ttp.is_mifr = true if pkg.is_mifr
      skip_validations << ttp
      # Only continue if we need to overwrite or its a new record
      return ttp unless ttp.new_record? || uploaded_file.overwrite || uploaded_file.read_only
      # Make sure it goes into our to_save array
      to_save << ttp
      # Marking ---------
      if t.markings.present?
        t.markings.each do |x|
          m = StixMarking.ingest(uploaded_file, x, ttp)
          if m.present?
            to_save << m
          end
        end
      end
      # package ttps
      if pkg.present? && pkg.class.to_s.match(/Package/)
        tps = TtpPackage.ingest(uploaded_file, ttp, pkg)
        if tps.present?
          tps.is_upload = true
          skip_validations << tps
          to_save << tps
        end
      end
      # ttp exploit targets
      if t.exploit_targets.present?
        t.exploit_targets.each do |et|
          tet = TtpExploitTarget.ingest(uploaded_file, et, ttp)
          next if tet.blank?
          tet.is_upload = true
          skip_validations << tet
          to_save << tet
        end
      end
      # attack patterns present?
      if t.attack_patterns.present?
        t.attack_patterns.each do |atp|
          ap = self.ingest_attack_pattern(uploaded_file, skip_validations, atp, user, ttp, to_save)
          next if ap.blank?
          ap.set_stix_id if ap.stix_id.nil?
          tap = TtpAttackPattern.ingest(uploaded_file, ap, ttp)
          if tap.present?
            tap.is_upload = true
            skip_validations << tap
            to_save << tap
          end
        end
      end
      ttp
    end
    # attack_pattern ------
    def ingest_attack_pattern(uploaded_file, skip_validations, ap, user, parent_obj, to_save)
      # First you ingest the AttackPattern
      
      atkptn = AttackPattern.ingest(uploaded_file, ap, user)
      return atkptn if atkptn.blank?
      atkptn.is_upload = true
      atkptn.is_ciscp = true if parent_obj.is_ciscp
      atkptn.is_mifr = true if parent_obj.is_mifr

      skip_validations << atkptn
      # Only continue if we need to overwrite or its a new record
      return atkptn unless atkptn.new_record? || uploaded_file.overwrite || uploaded_file.read_only
      # Make sure it goes into our to_save array
      to_save << atkptn
      # Marking ---------
      if ap.markings.present?
        ap.markings.each do |x|
          m = StixMarking.ingest(uploaded_file, x, atkptn)
          if m.present?
            to_save << m
          end
        end
      end
      atkptn
    end
    def ingest_observable(uploaded_file, skip_validations, observable, observable_type, parent_obj, to_save)
      
      return if !Object.const_defined?(observable_type)
      ob = observable_type.constantize.ingest(uploaded_file, observable, parent_obj)
      ob.is_upload = true
      ob.is_ciscp = true if parent_obj.is_ciscp
      ob.is_mifr = true if parent_obj.is_mifr
      skip_validations << ob
      # TODO: We are not supporting composite observables yet
      if observable.cybox_objects.present?
        sobj = observable.cybox_objects.first
        x = self.ingest_cybox_object(to_save, uploaded_file, skip_validations, sobj, parent_obj)
        return if x.blank?
        x = IngestUtilities.swap_if_needed(uploaded_file, x, to_save)
        x.is_upload = true
        x.is_ciscp = true if parent_obj.is_ciscp
        x.is_mifr = true if parent_obj.is_mifr
        skip_validations << x
        if sobj.respond_to?(:hashes) && sobj.hashes.present?
          x.file_hashes = self.ingest_file_hashes(to_save, uploaded_file, skip_validations, sobj, x)
        end
        if sobj.respond_to?(:win_registry_values) &&
            sobj.win_registry_values.present?
          x_registry_values = []
          sobj.win_registry_values.each do |i|
            x2 = self.ingest_cybox_object(to_save, uploaded_file, skip_validations, i, x)
            x2.is_upload = true
            skip_validations << x2
            self.ingest_object_markings(uploaded_file, i, x2, to_save)
            x_registry_values << x2
            to_save << x2
          end
          x.registry_values = x_registry_values
        end
        if sobj.respond_to?(:uri) && sobj.uri.present?
          x2 = x.uri.present? ? x.uri : self.ingest_cybox_object(to_save, uploaded_file, skip_validations, sobj.uri, x)
          # see if a uri already exists. first spoof the check since we skip if overwrite && Classification true
          uri_temp = IngestUtilities.spoof_swap(uploaded_file, x2, x2.read_only, uploaded_file.read_only, uploaded_file.overwrite, to_save)
          # we need to preserve the non saved one first because we do a replace later on in the duplication code
          if (uploaded_file.read_only || (uploaded_file.overwrite == true && Setting.CLASSIFICATION == true)) && !uri_temp.id.nil?
            x2.cybox_object_id = uri_temp.cybox_object_id + Setting.READ_ONLY_EXT
          elsif !uri_temp.id.blank?
            x.uri_object_id = uri_temp.cybox_object_id
            x2 = uri_temp
          end
          if x2.cybox_object_id.blank?
            x2.set_cybox_object_id
          end
          x2.is_upload = true

          x2.is_ciscp = true if parent_obj.is_ciscp
          x2.is_mifr = true if parent_obj.is_mifr
          skip_validations << x2
          self.ingest_object_markings(uploaded_file, sobj.uri, x2, to_save)
          x.uri = x2
          to_save << x2
        end
        if sobj.respond_to?(:links) && sobj.links.present?
          x_links = []
          x_uris = []
          sobj.links.each do |i|
            x2 = to_save.select {|link| link.present? && link.respond_to?(:cybox_object_id) && link.cybox_object_id == i.cybox_object_id}.first || self.ingest_cybox_object(to_save, uploaded_file, skip_validations, i, x)
            if x2.class == Link && x2.uri.present?
              # Check if the uri exists in the to_save array already
              uri_temp = to_save.select {|x| x.respond_to?(:uri_normalized) && x.uri_normalized == x2.uri.uri_normalized}.first || x2.uri
              # see if a uri already exists. first spoof the check since we skip if overwrite && Classification true
              uri_temp = IngestUtilities.spoof_swap(uploaded_file, uri_temp, uri_temp.read_only, uploaded_file.read_only, uploaded_file.overwrite, to_save)
              # we need to preserve the non saved one first because we do a replace later on in the duplication code
              if (uploaded_file.read_only || (uploaded_file.overwrite == true && Setting.CLASSIFICATION == true)) && !uri_temp.id.blank?
                x2.uri.cybox_object_id = uri_temp.cybox_object_id + Setting.READ_ONLY_EXT
              else
                x2.uri_object_id = uri_temp.cybox_object_id
                x2.uri = uri_temp
              end
              if x2.uri.cybox_object_id.blank?
                x2.uri.set_cybox_object_id
              end
              if !to_save.include?(x2.uri)
                x2.uri.is_upload = true

                x2.uri.is_ciscp = true if parent_obj.is_ciscp
                x2.uri.is_mifr = true if parent_obj.is_mifr
                skip_validations << x2.uri
                to_save << x2.uri
              end
            end
            x2.is_upload = true
            x2.is_ciscp = true if parent_obj.is_ciscp
            x2.is_mifr = true if parent_obj.is_mifr
            skip_validations << x2
            self.ingest_object_markings(uploaded_file, i, x2, to_save)
            if x2.class.name == 'Link'
              unless x.class.to_s == 'EmailMessage' and x.links.include? x2
                x_links << x2
              end
            else
              unless x.class.to_s == 'EmailMessage' and x.uris.include? x2
                x_uris << x2
              end
            end
            to_save << x2
          end
          x_links = x_links - x.links
          x_uris = x_uris - x.uris
          x.links << x_links
          x.uris << x_uris
        end
        if sobj.respond_to?(:attachments) && sobj.attachments.present?
          x_cybox_files = []
          sobj.attachments.each do |a|
            x2 = self.ingest_cybox_object(to_save, uploaded_file, skip_validations, a, x)
            next if x2.blank?
            x2.is_upload = true

            x2.is_ciscp = true if parent_obj.is_ciscp
            x2.is_mifr = true if parent_obj.is_mifr
            skip_validations << x2
            self.ingest_object_markings(uploaded_file, a, x2, to_save)
            # ingest the hashes for the files
            if a.respond_to?(:hashes) && a.hashes.present?
              x2.file_hashes = self.ingest_file_hashes(to_save, uploaded_file, skip_validations, a, x2)
            end
            x_cybox_files << x2
            to_save << x2
          end
          x.cybox_files = x_cybox_files
        end
        ob.remote_object_id = x.cybox_object_id if x.id.present?
        if ob.class == Observable
          ob.indicator = parent_obj
        else
          ob.course_of_action = parent_obj
        end
        self.ingest_object_markings(uploaded_file, sobj, x, to_save)
        to_save << x
        to_save << ob
      else # Observable/Parameter without a Cybox Object
        IngestUtilities.add_warning(uploaded_file,"#{sobj.class.to_s}: #{observable_type.constantize.to_s} with unsupported Cybox Object")
      end # --- End Cybox Objects
    end
    def ingest_cybox_object(to_save, uploader, skip_validations, obj, parent = nil)
      
      case obj.class.to_s
        when 'Stix::Native::CyboxAddress' then Address.ingest(uploader, obj)
        when 'Stix::Native::CyboxDomain' then Domain.ingest(uploader, obj)
        when 'Stix::Native::CyboxEmailMessage' then ingest_email_message(to_save, uploader, skip_validations, obj, parent)
        when 'Stix::Native::CyboxFile' then CyboxFile.ingest(uploader, obj)
        when 'Stix::Native::CyboxHash' then FileHash.ingest(uploader, obj, parent)
        when 'Stix::Native::CyboxMutex' then CyboxMutex.ingest(uploader, obj)
        when 'Stix::Native::CyboxLink' then Link.ingest(uploader, obj)
        when 'Stix::Native::CyboxWinRegistryKey' then Registry.ingest(uploader, obj)
        when 'Stix::Native::CyboxWinRegistryValue' then RegistryValue.ingest(uploader, obj, parent)
        when 'Stix::Native::CyboxNetworkConnection' then ingest_network_connection(to_save, uploader, skip_validations, obj, parent)
        when 'Stix::Native::CyboxDnsQuery' then ingest_dns_query(to_save, uploader, skip_validations, obj, parent)
        when 'Stix::Native::CyboxDnsRecord' then ingest_dns_record(to_save, uploader, skip_validations, obj, parent)
        when 'Stix::Native::CyboxURI' then Uri.ingest(uploader, obj)
        when 'Stix::Native::CyboxHttpSession' then HttpSession.ingest(uploader, obj)
        when 'Stix::Native::CyboxHostname' then Hostname.ingest(uploader, obj)
        when 'Stix::Native::CyboxPort' then Port.ingest(uploader, obj)
        when 'Stix::Native::CyboxQuestion' then Question.ingest(uploader, obj)
        when 'Stix::Native::CyboxResourceRecord' then ResourceRecord.ingest(uploader, obj)
        when 'Stix::Native::CyboxSocketAddress' then ingest_socket_address(to_save, uploader, skip_validations, obj, parent)
        when 'Stix::Native::CyboxLayer7Connections' then ingest_layer7_connections(to_save, uploader, skip_validations, obj, parent)
        else
          IngestUtilities.add_warning(uploader,"Unsupported Cybox Object: #{obj.class.to_s}")
      end
    end
    # Returns the parsed Socket Address Obj
    def ingest_socket_address(to_save, uploader, skip_validations, obj, parent = nil)
      # Socket Address Cybox Object includes 3 embedded objects.
      # We need to parse all 3 of the possible embedded objects and create connections
      socket_address = SocketAddress.ingest(uploader, obj)
      return nil if socket_address.blank?
      if !parent.nil?
        socket_address.is_ciscp = true if parent.is_ciscp
        socket_address.is_mifr = true if parent.is_mifr
      end
      parsed_embedded_objs = {
        ip_addresses: [],
        hostnames: [],
        ports: []
      }
      parsed_embedded_objs.keys.each do |key|
        embedded_objs = obj.send(key)
        if embedded_objs.present?
          embedded_objs.each do |x|
            parsed_obj = self.parse_sub_obj(to_save, uploader, skip_validations, x, socket_address)
            next if parsed_obj.blank?
            if socket_address.send(key).include?(parsed_obj)
              socket_address.send(key).delete(parsed_obj)
            end
            parsed_embedded_objs[key] << parsed_obj
          end
        end
      end
      socket_address.addresses << parsed_embedded_objs[:ip_addresses] unless socket_address.addresses.include?(parsed_embedded_objs[:ip_addresses])
      socket_address.hostnames << parsed_embedded_objs[:hostnames] unless socket_address.hostnames.include?(parsed_embedded_objs[:hostnames])
      socket_address.ports << parsed_embedded_objs[:ports] unless socket_address.ports.include?(parsed_embedded_objs[:ports])
      socket_address
    end
    # Returns the Parsed email Object
    def ingest_email_message(to_save, uploader, skip_validations, obj, parent = nil)
      
      email_message = EmailMessage.ingest(uploader, obj)
      return nil if email_message.blank?

      email_message.is_ciscp = true if parent.present? && parent.is_ciscp
      email_message.is_mifr = true if parent.present? && parent.is_mifr
      parsed_embedded_objs = {
        from: [],
        reply_to: [],
        sender: [],
        x_originating_ip: []
      }
      parsed_embedded_objs.keys.each do |key|
        embedded_obj = obj.send(key)
        if embedded_obj.present?
          parsed_obj = self.parse_sub_obj(to_save, uploader, skip_validations, embedded_obj, email_message)
          next if parsed_obj.blank?
          parsed_embedded_objs[key] << parsed_obj
        end
      end
      email_message.from_address = parsed_embedded_objs[:from][0] if parsed_embedded_objs[:from][0].present?
      email_message.sender_address = parsed_embedded_objs[:sender][0] if parsed_embedded_objs[:sender][0].present?
      email_message.reply_to_address = parsed_embedded_objs[:reply_to][0] if parsed_embedded_objs[:reply_to][0].present?
      email_message.x_ip_address = parsed_embedded_objs[:x_originating_ip][0] if parsed_embedded_objs[:x_originating_ip][0].present?
      email_message
    end
    # Returns an array of file hashes
    def ingest_file_hashes(to_save, uploader, skip_validations, obj, parent)
      
      x_file_hashes = []
      obj.hashes.each do |i|
        x2 = self.parse_sub_obj(to_save, uploader, skip_validations, i, parent)
        next if x2.blank?
        
        x_file_hashes << x2
      end
      x_file_hashes
    end
    # Returns the Parsed dns query Object
    def ingest_dns_query(to_save, uploader, skip_validations, obj, parent = nil)
      dns_query = DnsQuery.ingest(uploader, obj)
      return nil if dns_query.blank?
      if !parent.nil?
        dns_query.is_ciscp = true if parent.is_ciscp
        dns_query.is_mifr = true if parent.is_mifr
      end
      parsed_embedded_objs = {
        questions: [],
        answer_resource_records: [],
        authority_resource_records: [],
        additional_records: []
      }
      parsed_embedded_objs.keys.each do |key|
        embedded_obj = obj.send(key)
        if embedded_obj.present?
          embedded_obj.each do |sub_obj|
            parsed_obj = self.parse_sub_obj(to_save, uploader, skip_validations, sub_obj, dns_query)
            next if parsed_obj.blank?
            if key.to_s.include?("records")
              parsed_obj.record_type = key.to_s.singularize.titleize
              sub_obj.dns_records.each do |dns|
                parsed_dns = self.parse_sub_obj(to_save, uploader, skip_validations, dns, dns_query)
                next if parsed_dns.blank?
                parsed_obj.dns_records << parsed_dns
              end
            else
              sub_obj.qname.each do |uri|
                parsed_uri = self.parse_sub_obj(to_save, uploader, skip_validations, uri, dns_query)
                next if parsed_uri.blank?
                parsed_obj.uris << parsed_uri
              end
            end
            if dns_query.send(key).present?
              dns_query.send(key).delete(parsed_obj)
            end
            parsed_embedded_objs[key] << parsed_obj
          end
        end
      end
      dns_query.questions << parsed_embedded_objs[:questions] if parsed_embedded_objs[:questions].present?
      dns_query.answer_resource_records << parsed_embedded_objs[:answer_resource_records] if parsed_embedded_objs[:answer_resource_records].present?
      dns_query.authority_resource_records << parsed_embedded_objs[:authority_resource_records] if parsed_embedded_objs[:authority_resource_records].present?
      dns_query.additional_records << parsed_embedded_objs[:additional_records] if parsed_embedded_objs[:additional_records].present?
      dns_query
    end
    # Returns the Parsed dns record Object
    def ingest_dns_record(to_save, uploader, skip_validations, obj, parent = nil)
      
      dns_record = DnsRecord.ingest(uploader, obj)
      return nil if dns_record.blank?
      if !parent.nil?
        dns_record.is_ciscp = true if parent.is_ciscp
        dns_record.is_mifr = true if parent.is_mifr
      end
      embedded_obj = obj.ip_address
      if embedded_obj.present?
        parsed_obj = self.parse_sub_obj(to_save, uploader, skip_validations, embedded_obj, dns_record)
        if parsed_obj.present?
          dns_record.dns_address = parsed_obj
        end
      end
      embedded_obj = obj.domain_name
      if embedded_obj.present? && embedded_obj.class.to_s == 'Stix::Native::CyboxDomain'
        parsed_obj = self.parse_sub_obj(to_save, uploader, skip_validations, embedded_obj, dns_record)
        if parsed_obj.present?
          dns_record.dns_domain = parsed_obj
        end
      else
        # its a URI but we need to support it as a domain...
        parsed_obj = Domain.new
        HumanReview.adjust(embedded_obj, uploader)
        parsed_obj.name_condition = embedded_obj.uri_condition
        parsed_obj.name_raw = embedded_obj.name_raw
        parsed_obj.read_only = uploader.read_only
        parsed_obj = IngestUtilities.swap_if_needed(uploader, parsed_obj, to_save)
        parsed_obj.is_upload = true
        parsed_obj.is_ciscp = true if dns_record.is_ciscp
        parsed_obj.is_mifr = true if dns_record.is_mifr
        if parsed_obj.id.present? && parsed_obj.stix_markings.present?
          parsed_obj.stix_markings.destroy_all
        end
        self.ingest_object_markings(uploader, embedded_obj, parsed_obj, to_save)
        skip_validations << parsed_obj
        to_save << parsed_obj
        dns_record.dns_domain = parsed_obj
      end
      dns_record
    end
    def ingest_network_connection(to_save, uploader, skip_validations, obj, parent)
      network_connection = NetworkConnection.ingest(uploader, obj)
      return nil if network_connection.blank? || (network_connection.present? && network_connection.id.present? && uploader.overwrite == false)

        if !parent.nil?
          network_connection.is_ciscp = true if parent.is_ciscp
          network_connection.is_mifr = true if parent.is_mifr
        end
      if obj.source_socket_address.present?
        parsed_obj = self.parse_sub_obj(to_save, uploader, skip_validations, obj.source_socket_address, network_connection)
        if parsed_obj.present?
          network_connection.source_socket_address_obj = parsed_obj
          network_connection.source_socket_address = parsed_obj.addresses.first.address_value_raw if parsed_obj.addresses.present?
          network_connection.source_socket_is_spoofed = parsed_obj.addresses.first.is_spoofed if parsed_obj.addresses.present?
          network_connection.source_socket_hostname = parsed_obj.hostnames.first.hostname_raw if parsed_obj.hostnames.present?
          network_connection.source_socket_port = parsed_obj.ports.first.port if parsed_obj.ports.present?
        end
      end
      parsed_obj = nil
      if obj.dest_socket_address.present?
        parsed_obj = self.parse_sub_obj(to_save, uploader, skip_validations, obj.dest_socket_address, network_connection)
        if parsed_obj.present?
          network_connection.dest_socket_address_obj = parsed_obj
          network_connection.dest_socket_address = parsed_obj.addresses.first.address_value_raw if parsed_obj.addresses.present?
          network_connection.dest_socket_is_spoofed = parsed_obj.addresses.first.is_spoofed if parsed_obj.addresses.present?
          network_connection.dest_socket_hostname = parsed_obj.hostnames.first.hostname_raw if parsed_obj.hostnames.present?
          network_connection.dest_socket_port = parsed_obj.ports.first.port if parsed_obj.ports.present?
        end
      end
      if obj.layer7_connections.present?
        obj.layer7_connections.each do |x|
          parsed_obj = self.parse_sub_obj(to_save, uploader, skip_validations, x, network_connection)
          if parsed_obj.present?
            network_connection.layer_seven_connections << parsed_obj
          end
        end
      end
      
      network_connection
    end
    def ingest_layer7_connections(to_save, uploader, skip_validations, obj, parent=nil)
      layer7 = LayerSevenConnection.ingest(uploader, obj)
      return nil if layer7.blank? || (layer7.present? && layer7.id.present? && uploader.overwrite == false)
      if obj.http_session.present?
        parsed_obj = self.parse_sub_obj(to_save, uploader, skip_validations, obj.http_session, parent)
        if parsed_obj.present?
          layer7.http_session = parsed_obj
        end
      end
      if obj.dns_queries.present?
        obj.dns_queries.each do |dns|
          parsed_obj = self.parse_sub_obj(to_save, uploader, skip_validations, dns, parent)
          if parsed_obj.present?
            layer7.dns_queries << parsed_obj
          end
        end
      end
      layer7
    end
    def parse_sub_obj(to_save, uploader, skip_validations, parsed_stix, parent=nil)
      sub_obj = self.ingest_cybox_object(to_save, uploader, skip_validations, parsed_stix, parent)
      cs_class = nil
      if sub_obj.present?
        if (uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)) && parsed_stix.respond_to?(:markings) && parsed_stix.markings.present?
          isa_markings = parsed_stix.markings.select{|x| x.respond_to?(:marking_structures)}.collect{|x| x.marking_structures}.flatten.select{|x| x.class == Stix::Native::IsaMarkingAssertion}.first
          if isa_markings.present?
            cs_class = isa_markings.cs_classification
          end
        end
        sub_obj = IngestUtilities.swap_if_needed(uploader, sub_obj, to_save, {classification: cs_class})
        sub_obj.is_upload = true

        sub_obj.is_ciscp = true if sub_obj.respond_to?(:is_ciscp) && parent.present? && parent.is_ciscp
        sub_obj.is_mifr = true if sub_obj.respond_to?(:is_mifr) && parent.present? && parent.is_mifr
        if sub_obj.id.present? && sub_obj.stix_markings.present?
          sub_obj.stix_markings.destroy_all
        end
        self.ingest_object_markings(uploader, parsed_stix, sub_obj, to_save)
        sub_obj.set_cybox_object_id if sub_obj.respond_to?(:cybox_object_id)
        skip_validations << sub_obj
        to_save << sub_obj
      end
      sub_obj
    end
    def ingest_object_markings(uploader, parsed_obj, model_obj, to_save)
      
      return true unless parsed_obj.present? &&
          parsed_obj.respond_to?(:markings) && parsed_obj.markings.present? &&
          model_obj.present? && model_obj.respond_to?(:stix_markings)
      parsed_obj.markings.each { |marking|
        next if marking.to_s.downcase.include?("aisconsent") && model_obj.class != StixPackage
        if marking.remote_object_field.nil?
          sm = StixMarking.ingest(uploader, marking, model_obj)
        elsif model_obj.respond_to?(marking.remote_object_field)
          sm = StixMarking.ingest(uploader, marking, model_obj)
        else
          sm = nil
        end
        to_save << sm
      }
      true
    end
    def is_ais_provider_user?(curr_user)
      curr_user.present? && Setting.AIS_PROVIDER.present? &&
          Setting.AIS_PROVIDER.split(',').collect(&:strip).
              include?(curr_user.username)
    end
  end
end


