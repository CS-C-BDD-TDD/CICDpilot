
namespace :big do
  task :migration! => :environment do |*args|
    ActiveRecord::Base.record_timestamps = false

    # Release 6 Tables ---------------------------------------------------------------
    class Address < ActiveRecord::Base; self.table_name = 'r6_cybox_addresses' end
    class Confidence < ActiveRecord::Base; self.table_name = 'r6_stix_confidences' end
    class CyboxCustomObject < ActiveRecord::Base; self.table_name = 'r6_cybox_custom_objects' end
    class CyboxFile < ActiveRecord::Base; self.table_name = 'r6_cybox_files' end
    class CyboxFileHash < ActiveRecord::Base; self.table_name = 'cybox_file_hashes' end
    class DnsRecord < ActiveRecord::Base; self.table_name = 'r6_cybox_dns_records' end
    class Domain < ActiveRecord::Base; self.table_name = 'r6_cybox_domains' end
    class EmailMessage < ActiveRecord::Base; self.table_name = 'r6_cybox_email_messages' end
    class Group < ActiveRecord::Base; self.table_name = 'r6_groups' end
    class GroupPermission < ActiveRecord::Base; self.table_name = 'r6_groups_permissions' end
    class Indicator < ActiveRecord::Base; self.table_name = 'r6_stix_indicators' end
    class IndicatorsPackage < ActiveRecord::Base; self.table_name = 'r6_stix_ind_pack'; end
    class Notes < ActiveRecord::Base; self.table_name = 'r6_notes' end
    class Observable < ActiveRecord::Base; self.table_name = 'r6_cybox_observables' end
    class Organization < ActiveRecord::Base; self.table_name = 'r6_organizations' end
    class OriginalInput < ActiveRecord::Base; self.table_name = 'r6_original_input' end
    class Permission < ActiveRecord::Base; self.table_name = 'r6_permissions' end
    class SearchLog < ActiveRecord::Base; self.table_name = 'r6_search_logs' end
    class SectionHash < ActiveRecord::Base; self.table_name = 'r6_legacy_section_hashes' end
    class StixSighting < ActiveRecord::Base; self.table_name = 'r6_stix_sightings' end
    class StixPackage < ActiveRecord::Base; self.table_name = 'r6_stix_packages' end
    class StixRelatedObject < ActiveRecord::Base; self.table_name="r6_stix_related_objects" end
    class Tag < ActiveRecord::Base; self.table_name = 'r6_tags' end
    class TagAssignment < ActiveRecord::Base; self.table_name = 'r6_tag_assignments' end
    class Uri < ActiveRecord::Base; self.table_name = 'r6_cybox_uris' end
    class UploadedFile < ActiveRecord::Base; self.table_name = 'r6_uploaded_files'; end
    class User < ActiveRecord::Base; self.table_name = 'r6_users'; end
    class UserGroup < ActiveRecord::Base; self.table_name = 'r6_users_groups' end
    class WeatherMapData < ActiveRecord::Base; self.table_name="r6_weather_map_data" end
    class YaraRule < ActiveRecord::Base; self.table_name="r6_legacy_yara_rules" end

    # Release 5 Tables ---------------------------------------------------------------
    class R5Tracking < ActiveRecord::Base; self.table_name = 'r5tracking' end
    class R5Destination < ActiveRecord::Base; self.table_name = 'r5destinations' end
    class R5Attachment < ActiveRecord::Base; establish_connection :release5; self.table_name="attachments" end
    class R5Collection < ActiveRecord::Base; establish_connection :release5; self.table_name="collections" end
    class R5Dns < ActiveRecord::Base; establish_connection :release5; self.table_name="dns_resolution_elements" end
    class R5Domain < ActiveRecord::Base; establish_connection :release5; self.table_name="domain_elements" end
    class R5DomainInfo < ActiveRecord::Base; establish_connection :release5; self.table_name="domain_info" end
    class R5E2AlertStatistics < ActiveRecord::Base; establish_connection :release5; self.table_name="e2_alert_statistics" end
    class R5E2Signatures < ActiveRecord::Base; establish_connection :release5; self.table_name="e2_signatures" end
    class R5E2Subdomains < ActiveRecord::Base; establish_connection :release5; self.table_name="e2_subdomains" end
    class R5Email < ActiveRecord::Base; establish_connection :release5; self.table_name="email_elements" end
    class R5File < ActiveRecord::Base; establish_connection :release5; self.table_name="phile_elements" end
    class R5ImpactedOrgs < ActiveRecord::Base; establish_connection :release5; self.table_name="impacted_orgs" end
    class R5IPv4 < ActiveRecord::Base; establish_connection :release5; self.table_name="ipv4_elements" end
    class R5IPv6 < ActiveRecord::Base; establish_connection :release5; self.table_name="ipv6_elements" end
    class R5OldMD5Hash < ActiveRecord::Base; establish_connection :release5; self.table_name="old_md5_hashes" end
    class R5OldPhiles2 < ActiveRecord::Base; establish_connection :release5; self.table_name="old_philes2" end
    class R5Organization < ActiveRecord::Base; establish_connection :release5; self.table_name="organizations" end
    # class R5Philes: See R5File
    class R5Phrases < ActiveRecord::Base; establish_connection :release5; self.table_name="phrase_elements" end
    class R5Relationship < ActiveRecord::Base; establish_connection :release5; self.table_name="relationships" end
    class R5Search < ActiveRecord::Base; establish_connection :release5; self.table_name = 'searches' end
    class R5SectionHash < ActiveRecord::Base; establish_connection :release5; self.table_name = 'section_hashes' end
    class R5Sighting < ActiveRecord::Base; establish_connection :release5; self.table_name="sightings" end
    class R5StixReport < ActiveRecord::Base; establish_connection :release5; self.table_name="stix_reports" end
    class R5TaskHistories < ActiveRecord::Base; establish_connection :release5; self.table_name="task_histories" end
    class R5User < ActiveRecord::Base; establish_connection :release5; self.table_name="users" end
    class R5Uri < ActiveRecord::Base; establish_connection :release5; self.table_name="uri_elements" end
    class R5Workspace < ActiveRecord::Base; establish_connection :release5; self.table_name="workspaces" end
    class R5WeatherMapData < ActiveRecord::Base; establish_connection :release5; self.table_name="weather_map_data" end
    class R5YaraRule < ActiveRecord::Base; establish_connection :release5; self.table_name="yara_rules" end

    CONFIDENCE_MAP = {unknown: 0, low: 1, medium: 2, high: 3}

    def r5_type_to_table(type)
      return R5Domain.table_name if type == 'DomainElement'
      return R5Uri.table_name if type == 'UriElement'
      return R5Email.table_name if type == 'EmailElement'
      return R5IPv4.table_name if type == 'Ipv4Element'
      return R5IPv6.table_name if type == 'Ipv6Element'
      return R5Dns.table_name if type == 'DnsResolutionElement'
      return R5Phrases.table_name if type == 'PhraseElement'
      return R5File.table_name if type == 'PhileElement'
      raise "I don't know the table_name for type '#{type}'"
    end
    def r5type_to_r6model(type)
      return Domain if type == 'DomainElement'
      return Uri if type == 'UriElement'
      return EmailMessage if type == 'EmailElement'
      return Address if type == 'Ipv4Element'
      return Address if type == 'Ipv6Element'
      return DnsRecord if type == 'DnsResolutionElement'
      return CyboxCustomObject if type == 'PhraseElement'
      return CyboxFile if type == 'PhileElement'
      raise "I don't know the r6model for type '#{type}'"
    end
    def create_indicator_and_observable(old_ele, new_obs, obj_type, title)
      obs = Observable.new
      obs.guid = SecureRandom.uuid
      if old_ele.has_attribute?(:stix_observable_id)
        obs.cybox_object_id = old_ele.stix_observable_id
      end
      obs.cybox_object_id = SecureRandom.cybox_object_id(obs) if obs.cybox_object_id.blank?
      obs.remote_object_id = new_obs.cybox_object_id
      obs.remote_object_type = obj_type
      obs.created_at = old_ele.created_at
      obs.updated_at = old_ele.created_at
      ind = Indicator.new
      ind.guid = old_ele.guid
      ind.guid = SecureRandom.uuid if ind.guid.blank?
      if old_ele.has_attribute?(:stix_indicator_id)
        ind.stix_id = old_ele.stix_indicator_id
      end
      ind.stix_id = SecureRandom.stix_id(ind) if ind.stix_id.blank?

      if title.blank?
        ind.title = 'UNKNOWN-TITLE'
      else
        ind.title = title
      end

      ind.description = "US-CERT Indicator"
      ind.downgrade_request_id = old_ele.downgrade_request_id
      ind.legacy_category= old_ele.category
      ind.legacy_color = old_ele.color
      ind.indicator_type = old_ele.indicator_type.presence || :needs_definition
      ind.created_at = old_ele.created_at
      ind.updated_at = old_ele.created_at
      obs.stix_indicator_id = ind.stix_id
      r5_created_by = R5User.find(old_ele.created_by_id) if old_ele.created_by_id.present?
      r5_updated_by = R5User.find(old_ele.updated_by_id) if old_ele.updated_by_id.present?
      r5_created_by ||= R5User.find(old_ele.user_id) if old_ele.user_id.present?
      user = User.find_by_username(r5_created_by.username) if r5_created_by.present?
      ind.created_by_user_guid = user.guid if user.present?
      ind.updated_by_user_guid = User.find_by_username(r5_updated_by.username).guid if r5_updated_by.present?
      ind.created_by_organization_guid = Organization.find_by_long_name(R5Organization.find(r5_created_by.organization_id).long_name).guid if r5_created_by.present?
      ind.updated_by_organization_guid = Organization.find_by_long_name(R5Organization.find(r5_updated_by.organization_id ).long_name).guid if r5_updated_by.present?
      ind.legacy_color = old_ele.color
      ind.legacy_category = old_ele.category
      obs.save!
      R5Destination.create!(r5table: old_ele.class.table_name, r5id: old_ele.id, r6table:obs.class.table_name, r6id:obs.id)
      print "o".green
      ind.save!
      R5Destination.create!(r5table: old_ele.class.table_name,r5id: old_ele.id, r6table:ind.class.table_name, r6id: ind.id)
      print "i".green
      create_notes(ind,old_ele,user)
      create_confidence(ind,old_ele,user)
      return ind, obs, user
    end
    def create_notes(ind,old_ele,user)
      n = Notes.where(target_class: 'Indicator', target_guid: ind.guid)
      if n.empty?
        unless old_ele.notes.blank?
          notes = Notes.new
          notes.guid = SecureRandom.uuid
          notes.target_class = 'Indicator'
          notes.target_guid = ind.guid
          if user
            notes.user_guid = user.guid
          end
          notes.note = old_ele.notes
          notes.created_at = old_ele.created_at
          notes.updated_at = old_ele.updated_at
          notes.save
          print 'n'.green
        end
        unless old_ele.reason_added.blank?
          notes = Notes.new
          notes.guid = SecureRandom.uuid
          notes.target_class = 'Indicator'
          notes.target_guid = ind.guid
          if user
            notes.user_guid = user.guid
          end
          notes.note = "Reason Added: "+old_ele.reason_added
          notes.created_at = old_ele.created_at
          notes.updated_at = old_ele.updated_at
          notes.save
          print 'n'.green
        end
        # Handle the analysis field from phile_elements
        if old_ele.has_attribute?(:analysis)
          unless old_ele.analysis.blank?
            notes = Notes.new
            notes.guid = SecureRandom.uuid
            notes.target_class = 'Indicator'
            notes.target_guid = ind.guid
            if user
              notes.user_guid = user.guid
            end
            notes.note = "Analysis: "+old_ele.analysis
            notes.created_at = old_ele.created_at
            notes.updated_at = old_ele.updated_at
            notes.save
            print 'n'.green
          end
        end
      else
        print 'n'.blue
      end
    end

    def create_confidence(ind,old_ele,user)
      if old_ele.confidence and old_ele.confidence != 'Unknown'
        c = Confidence.where(remote_object_id: ind.guid, remote_object_type: 'Indicator')
        if c.empty?
          conf = Confidence.new
          conf.remote_object_id = ind.guid
          conf.remote_object_type = 'Indicator'
          conf.value = old_ele.confidence.downcase
          conf.confidence_num = CONFIDENCE_MAP[old_ele.confidence.downcase.to_sym]
          #conf.is_official = false
          conf.source = 'US-CERT'
          conf.description = 'US-CERT'
          conf.guid = SecureRandom.uuid
          conf.created_at = old_ele.created_at
          if user
            conf.user_guid = user.guid
          end
          conf.save
          print 'c'.green
        else
          print 'c'.blue
        end
      end
    end

    def migrate_indicator(ind, old_ele, new_obs)
      user = nil
      r_users = User.where(r5_id: old_ele.created_by_id) + User.where(r5_id: old_ele.user_id)
      if r_users.any?
        user = r_users.first
      end
      if old_ele.container_type == 'Sighting'
        r5_sightings = R5Sighting.where(id: old_ele.container_id, deleted_at: nil)
        if r5_sightings.any?
          r5_sighting = r5_sightings.first
          if r5_sighting.occurred_at.present?
            ss = StixSighting.new
            ss.sighted_at = r5_sighting.occurred_at
            ss.description = r5_sighting.notes
            ss.stix_indicator_id = ind.stix_id
            ss.save
            print "s".green
          end
        end
        r6sighting = nil
        r6sightings = R5Destination.where(r5table: R5Sighting.table_name, r5id: old_ele.container_id, r6table: StixPackage.table_name)
        if r6sightings.any?
          r6sighting = StixPackage.find(r6sightings.first.r6id)
        end
        #raise "Could not find STIX Package created from r5 sighting (#{old_ele.container_id})" if r6sighting.nil?
        # Deleted sightings would trigger this
        if r6sighting.present?
          IndicatorsPackage.create!(stix_package_id: r6sighting.stix_id, stix_indicator_id: ind.stix_id, created_at: ind.created_at, updated_at: ind.updated_at, guid: SecureRandom.uuid)
          R5Destination.create!(r5table: R5Sighting.table_name, r5id: old_ele.container_id, r6table: Indicator.table_name, r6id: ind.id)
          print "ip".green
        end
      end
      if old_ele.container_type == 'Collection'
        r5_collections = R5Collection.where(id: old_ele.container_id)
        if r5_collections.any?
          r5_collection = r5_collections.first
          tags = Tag.where(name: r5_collection.name, user_guid: nil)
          tag = nil
          if tags.any?
            tag = tags.first
          else
            user_guid = nil
            users = User.where(r5_id: r5_collection.user_id)
            if users.any?
              user_guid = users.first.guid
            end
            # If a user guid is set, it's not a system tag
            tag = Tag.create!(name: r5_collection.name, name_normalized: r5_collection.name.downcase, r5_collection_id: r5_collection.id, guid: SecureRandom.uuid)
            R5Destination.create!(r5table: r5_collection.class.table_name, r5id: r5_collection.id, r6table:tag.class.table_name, r6id:tag.id)
            print "t".green
          end
          user_guid = nil
          user_guid = user.guid if user.present?
          r_ta = TagAssignment.where(remote_object_guid: ind.guid, remote_object_type: 'Indicator', tag_guid: tag.guid)
          if r_ta.empty?
            TagAssignment.create!(created_at: old_ele.added_at.presence || old_ele.created_at, remote_object_guid: ind.guid, remote_object_type: 'Indicator', tag_guid: tag.guid, user_guid: user_guid, guid: SecureRandom.uuid)
            print "a".green
          else
            print "a".blue
          end
        end
      end

      if old_ele.container_type == 'Workspace'
        r5_workspaces = R5Workspace.where(id: old_ele.container_id)
        if r5_workspaces.any?
          r5_workspace = r5_workspaces.first
          user_guid = nil
          users = User.where(r5_id: r5_workspace.user_id)
          if users.any?
            # We need to have a user_guid in order to build a user tag
            user_guid = users.first.guid

            # Beginning of indented code
            tags = Tag.where(name: r5_workspace.name, user_guid: user_guid)
            tag = nil
            if tags.any?
              tag = tags.first
            else
              # If a user guid is set, it's not a system tag
              tag = Tag.create!(name: r5_workspace.name, name_normalized: r5_workspace.name.downcase, guid: SecureRandom.uuid, user_guid: user_guid)
              print "t".green
            end
            r_ta = TagAssignment.where(remote_object_guid: ind.guid, remote_object_type: 'Indicator', tag_guid: tag.guid)
            if r_ta.empty?
              TagAssignment.create!(created_at: old_ele.added_at.presence || old_ele.created_at, remote_object_guid: ind.guid, remote_object_type: 'Indicator', tag_guid: tag.guid, user_guid: user_guid, guid: SecureRandom.uuid)
              print "a".green
            else
              print "a".blue
            end
            # End of indented code

          end
        end
      end

      if old_ele.container_type == 'StixReport'
        r5_reports = R5StixReport.where(id: old_ele.container_id)
        if r5_reports.any?
          r5_report = r5_reports.first
          user_guid = nil
          users = User.where(r5_id: r5_report.user_id)
          if users.any?
            user_guid = users.first.guid
          end
          packages = StixPackage.where(title: r5_report.name, created_by_user_guid: user_guid)
          if packages.any?
            package = packages.first
          else
            package = StixPackage.new
            package.guid = SecureRandom.uuid
            package.title = r5_report.name
            package.created_by_user_guid = user_guid
            package.description = r5_report.description
            package.legacy_color = r5_report.color
            package.stix_id = r5_report.stix_id
            package.stix_id = SecureRandom.stix_id(package) if package.stix_id.blank?
            # Not needed, since we're not ported REL5 UIEF upload data
            #package.uploaded_file_id = r5_report.uploaded_file_id
            package.created_at = r5_report.created_at
            package.r5_container_type = r5_report.class.to_s
            package.r5_container_id = r5_report.id
            package.updated_at = r5_report.updated_at
            package.save!
          end
          i_p = IndicatorsPackage.where(stix_package_id: package.stix_id,stix_indicator_id: ind.stix_id)
          if i_p.empty?
            IndicatorsPackage.create!(stix_package_id: package.stix_id, stix_indicator_id: ind.stix_id, created_at: ind.created_at, updated_at: ind.updated_at, guid: SecureRandom.uuid)
            print "P".green
          else
            print "P".blue
          end
        end
      end

      if old_ele.has_attribute?(:excluded_from_e1) && old_ele.excluded_from_e1?
        t = Tag.find_by_name('excluded-from-e1')
        if t.present?
          r_ta = TagAssignment.where(remote_object_guid: ind.guid, remote_object_type: 'Indicator', tag_guid: t.guid)
          if r_ta.empty?
            user_guid = nil
            user_guid = user.guid if user.present?
            TagAssignment.create!(created_at: old_ele.added_at.presence || old_ele.created_at, remote_object_guid: ind.guid, remote_object_type: 'Indicator', tag_guid: t.guid, user_guid: user_guid, guid: SecureRandom.uuid)
            print "a".green
          else
            print "a".blue
          end
        end
      end
    end

    puts ""
    puts "Release 5 to Release 6 Data Migration"
    puts ""
    puts "Organizations"
    R5Organization.find_in_batches do |group|
      group.each do |old_o|
        r = R5Tracking.where(table: "organizations", old_id: old_o.id)
        if r.empty?
          o = Organization.new
          o.r5_id = old_o.id
          o.long_name = old_o.long_name
          o.short_name = old_o.short_name
          o.contact_info = old_o.contact_info
          o.category = old_o.category
          o.releasability_mask = old_o.releasability_mask
          o.guid = SecureRandom.uuid
          o.save
          R5Tracking.create!(table: 'organizations', old_id: old_o.id)
          print "o".green
        else
          print "o".blue
        end
      end
    end
    puts ""

    puts "Roles"
    # First create permissions
    yml = YAML.load_file('config/permissions.yml')
    (yml[Rails.env]||[]).each do |name,attributes|
      if Permission.find_by_name(name)
        print "p".blue
        next
      end

      p = Permission.new
      p.name = name
      p.display_name = attributes['display_name']
      p.description = attributes['description']
      p.created_at = Time.now
      p.updated_at = Time.now
      p.guid = SecureRandom.uuid
      p.save
      print "p".green
    end
    # Now create groups with the proper permissions
    yml = YAML.load_file('config/groups.yml')
    yml.each do |name,attributes|
      if Group.find_by_name(attributes['name'])
        print "g".blue
      else
        g=Group.new
        g.name = attributes['name']
        g.description = attributes['description']
        g.created_at = Time.now
        g.updated_at = Time.now
        g.guid = SecureRandom.uuid
        g.save
        unless attributes['permissions'].nil?
          perms=[]
          permissions=attributes['permissions'].strip.split /\s+/
          permissions.each do |permission|
            p=Permission.find_by_name(permission)
            gp=GroupPermission.new
            gp.group_id = g.id
            gp.permission_id = p.id
            gp.created_at = Time.now
            gp.guid = SecureRandom.uuid
            gp.save
          end
        end
        print "g".green
      end
    end
    puts ""

    old_role_to_group_name = {
      'admin' => "Admin",
      'data_admin' => "Data Admin",
      'nsd_data_auditor' => "NSD Data Auditor",
      'trusted_user' => "Trusted User",
      'contributor' => "Contributor",
      'metrics_viewer' => "Metrics Viewer",
      'all_metrics_viewer' => "All Metrics Viewer",
      'limited_viewer' => "Limited Viewer"
    }

    # users depends on organizations and roles
    puts "Users"
    R5User.find_in_batches do |group|
      group.each do |old_u|
        r = R5Tracking.where(table: "users", old_id: old_u.id)
        if r.empty?
          u = User.new
          u.r5_id = old_u.id
          u.username = old_u.username
          u.first_name = old_u.first_name
          u.last_name = old_u.last_name
          u.email = old_u.email
          u.phone = old_u.phone
          u.password_hash = old_u.password_hash
          u.password_salt = old_u.password_salt
          r = Organization.where(r5_id: old_u.organization_id)
          if r.any?
            u.organization_guid = r.first.guid
          end
          u.locked_at = old_u.locked_at
          u.logged_in_at = old_u.logged_in_at
          u.notes = old_u.notes
          u.failed_login_attempts = old_u.failed_login_attempts
          u.expired_at = old_u.expired_at
          u.disabled_at = old_u.disabled_at
          u.password_change_required = old_u.password_change_required
          u.password_changed_at = old_u.password_changed_at
          u.terms_accepted_at = old_u.terms_accepted_at
          #u.releasability_mask = old_u.releasability_mask
          u.hidden_at = old_u.hidden_at
          u.throttle = old_u.throttle
          u.machine = old_u.machine
          u.created_at = old_u.created_at
          u.updated_at = old_u.updated_at
          u.guid = SecureRandom.uuid if u.guid.blank?
          u.save
          g=Group.find_by_name(old_role_to_group_name[old_u.role])
          if g
            ug=UserGroup.new
            ug.user_guid = u.guid
            ug.group_id = g.id
            ug.created_at = Time.now
            ug.guid = SecureRandom.uuid
            ug.save
          end
          R5Tracking.create!(table: 'users', old_id: old_u.id)
          print "u".green
        else
          print "u".blue
        end
      end
    end
    puts ""

    puts "Sightings"
    R5Sighting.find_in_batches do |group|
      group.each do |old_s|
        # Skip deleted entries
        next if old_s.deleted_at.present?
        r = R5Tracking.where(table: "sightings", old_id: old_s.id)
        if r.empty?
          R5Tracking.create!(table: 'sightings', old_id: old_s.id)
          sp = StixPackage.new
          sp.r5_container_id = old_s.id
          sp.r5_container_type = 'Sighting'
          sp.created_at = old_s.created_at
          sp.description = "#{old_s.notes}"
          sp.description = "#{sp.description} Handling Instructions: #{old_s.handling_instructions}" if old_s.handling_instructions.present?
          sp.description = "#{sp.description} Impacted Organization: #{old_s.impacted_organization}" if old_s.impacted_organization.present?
          sp.short_description = old_s.summary
          sp.guid = SecureRandom.uuid
          sp.stix_id = SecureRandom.stix_id(sp)
          sp.stix_timestamp = old_s.created_at
          sp.title = old_s.name
          sp.updated_at = old_s.updated_at
          sp.legacy_color = old_s.color
          sp.legacy_category = old_s.category
          r_users = User.where(r5_id: old_s.user_id)
          if r_users.any?
            user = r_users.first
            sp.username = user.username
          end
          sp.save
          R5Destination.create!(r5table: old_s.class.table_name, r5id: old_s.id, r6table:sp.class.table_name, r6id:sp.id)
          print "p".green
        else
          print "p".blue
        end
      end
    end
    puts ""

    puts "Collections"
    R5Collection.find_in_batches do |group|
      group.each do |old_c|
        # Skip deleted entries
        next if old_c.deleted_at.present?
        r = R5Tracking.where(table: "collections", old_id: old_c.id)
        if r.empty?
          R5Tracking.create!(table: 'collections', old_id: old_c.id)
          #TODO check to see if the collection exists
          t = Tag.new
          t.r5_collection_id = old_c.id
          t.name = old_c.name
          t.name_normalized = old_c.name.downcase
          r_users = User.where(r5_id: old_c.user_id)
          if r_users.any?
            user = r_users.first
            t.user_guid = user.guid
          end
          t.created_at = old_c.created_at
          t.updated_at = old_c.updated_at
          t.guid = SecureRandom.uuid
          t.save
          R5Destination.create!(r5table: old_c.class.table_name, r5id: old_c.id, r6table:t.class.table_name, r6id:t.id)
          print "t".green
        else
          print "t".blue
        end
      end
    end
    puts ""

    puts "Stix Reports"
    R5StixReport.find_in_batches do |group|
      group.each do |old_s|
        next if old_s.deleted_at.present?
        r = R5Tracking.where(table: "stix_reports",old_id: old_s.id)
        if r.empty?
          R5Tracking.create!(table: 'stix_reports', old_id: old_s.id)

          user_guid = nil
          users = User.where(r5_id: old_s.user_id)
          if users.any?
            user_guid = users.first.guid
          end
          unless StixPackage.exists?(title: old_s.name, created_by_user_guid: user_guid)
            package = StixPackage.new
            package.title = old_s.name
            package.created_by_user_guid = user_guid
            package.description = old_s.description
            package.legacy_color = old_s.color
            package.created_at = old_s.created_at
            package.r5_container_type = old_s.class.to_s
            package.r5_container_id = old_s.id
            package.guid = SecureRandom.uuid
            package.stix_id = old_s.stix_id
            package.stix_id = SecureRandom.stix_id(package) unless package.stix_id.present?
            package.updated_at = old_s.updated_at
            package.save
            R5Destination.create!(r5table: old_s.class.table_name, r5id: old_s.id, r6table:package.class.table_name, r6id:package.id)
            print "r".green
          end
        else
          print "r".blue
        end
      end
    end
    puts ""

    # depends on users, containers
    puts "Domains"
    R5Domain.find_in_batches do |group|
      group.each do |old_d|
        # Skip deleted entries
        next if old_d.deleted_at.present?
        r = R5Tracking.where(table: "domain_elements", old_id: old_d.id)
        if r.any?
          print "d".blue
          next
        end
        R5Tracking.create!(table: 'domain_elements', old_id: old_d.id)
        new_domain = nil
        r = Domain.where(name_normalized: old_d.name_normalized)
        if r.empty?
          new_domain = Domain.new
          new_domain.guid = SecureRandom.uuid if new_domain.guid.blank?
          new_domain.cybox_object_id = SecureRandom.cybox_object_id(new_domain)
          new_domain.name_raw = old_d.name_raw
          new_domain.name_condition = 'Equals'
          new_domain.name_normalized = old_d.name_normalized
          new_domain.root_domain = old_d.root_domain
          new_domain.created_at = old_d.created_at
          new_domain.updated_at = old_d.updated_at
          new_domain.save
          R5Destination.create!(r5table: old_d.class.table_name, r5id: old_d.id, r6table:new_domain.class.table_name, r6id:new_domain.id)
          print "d".green
        else
          # We are importing this domain element for the first time, but we already have an instance of the domain in our system
          new_domain = r.first
        end
        # see if the domain already has an indicator.  If not, create one
        r = Observable.where(remote_object_id: new_domain.cybox_object_id, remote_object_type: 'Domain')
        obs = nil
        ind = nil
        if r.empty?
          ind, obs, user = create_indicator_and_observable(old_d, new_domain, 'Domain', old_d.name_raw)
        else
          ind = Indicator.where(stix_id: r.first.stix_indicator_id).first
          print 'oi'.blue
        end
        migrate_indicator(ind, old_d, new_domain)

      end
    end
    puts ""

    puts "IPv4s"
    R5IPv4.find_in_batches do |group|
      group.each do |old_i|
        # Skip deleted entries
        next if old_i.deleted_at.present?
        r = R5Tracking.where(table: "ipv4_elements", old_id: old_i.id)
        if r.any?
          print "a".blue
          next
        end
        new_address = nil
        R5Tracking.create!(table: 'ipv4_elements', old_id: old_i.id)
        r = Address.where(address_value_normalized: old_i.address_normalized)
        if r.empty?
          new_address = Address.new
       
          new_address.category = 'ipv4-addr'

          new_address.address_value_raw = old_i.address_raw
          new_address.address_value_normalized = old_i.address_normalized
          new_address.guid = SecureRandom.uuid
          new_address.cybox_object_id = SecureRandom.cybox_object_id(new_address)
          new_address.created_at = old_i.created_at
          new_address.updated_at = old_i.updated_at
          ip = IPAddress::IPv4.new(old_i.address_normalized.strip)
          new_address.ip_value_calculated_start = ip.network.to_i
          new_address.ip_value_calculated_end = ip.broadcast.to_i
          new_address.save
          R5Destination.create!(r5table: old_i.class.table_name, r5id: old_i.id, r6table:new_address.class.table_name, r6id:new_address.id)
          print "a".green
        else
          new_address = r.first
        end
        # see if the address already has an indicator.  If not, create one
        r = Observable.where(remote_object_id: new_address.cybox_object_id, remote_object_type: 'Address')
        obs = nil
        ind = nil
        if r.empty?
          ind,obs,user = create_indicator_and_observable(old_i, new_address, 'Address', old_i.address_raw)
          if old_i.excluded_from_e1
            t = Tag.find_by_name('excluded-from-e1')
            if t.present?
              user_guid = nil
              user_guid = user.guid if user.present?
              TagAssignment.create!(created_at: old_i.added_at.presence || old_i.created_at, remote_object_guid: ind.guid, remote_object_type: 'Indicator', tag_guid: t.guid, user_guid: user_guid, guid: SecureRandom.uuid)
            end
          end
        else
          ind = Indicator.where(stix_id: r.first.stix_indicator_id).first
          print 'oi'.blue
        end
        migrate_indicator(ind, old_i, new_address)
      end
    end
    puts ""

    puts "Emails"
    R5Email.find_in_batches do |group|
      group.each do |old_e|
        # Skip deleted entries
        next if old_e.deleted_at.present?
        r = R5Tracking.where(table: "email_elements", old_id: old_e.id)
        if r.any?
          print "e".blue
          next
        end
        new_email = nil
        R5Tracking.create!(table: 'email_elements', old_id: old_e.id)
        if old_e.sender_address_raw && old_e.subject
          r = EmailMessage.where(sender_raw: old_e.sender_address_raw).where(subject: old_e.subject)
        elsif old_e.sender_address_raw
          r = EmailMessage.where(sender_raw: old_e.sender_address_raw)
        else
          r = EmailMessage.where(subject: old_e.subject)
        end
        if r.empty?
          new_email = EmailMessage.new
          new_email.sender_raw = old_e.sender_address_raw
          new_email.sender_normalized = old_e.sender_address_normalized
          new_email.subject = old_e.subject
          new_email.email_date = old_e.occurred_at
          new_email.raw_header = old_e.header
          new_email.created_at = old_e.created_at
          new_email.updated_at = old_e.updated_at
          # If there is a guid, we don't want it on both the observable and the indicator, just generate a new one
          new_email.guid = SecureRandom.uuid
          new_email.cybox_object_id = SecureRandom.cybox_object_id(new_email)
          new_email.save
          R5Destination.create!(r5table: old_e.class.table_name, r5id: old_e.id, r6table:new_email.class.table_name, r6id:new_email.id)
          print "e".green
        else
          new_email = r.first
        end
        # see if the email already has an indicator.  If not, create one
        r = Observable.where(remote_object_id: new_email.cybox_object_id, remote_object_type: 'EmailMessage')
        obs = nil
        ind = nil
        if r.empty?
          ind,obs,user = create_indicator_and_observable(old_e, new_email, 'EmailMessage', old_e.sender_address_raw)
        else
          ind = Indicator.where(stix_id: r.first.stix_indicator_id).first
          print 'oi'.blue
        end
        migrate_indicator(ind, old_e, new_email)

      end
    end
    puts ""

    puts "Uris"
    R5Uri.find_in_batches do |group|
      group.each do |old_u|
        next if old_u.deleted_at.present?
        r = R5Tracking.where(table: "uri_elements", old_id: old_u.id)
        if r.any?
          print "e".blue
          next
        end
        new_uri = nil
        R5Tracking.create!(table: 'uri_elements', old_id: old_u.id)
        r = Uri.where(uri_normalized: old_u.uri_normalized)
        if r.empty?
          new_uri = Uri.new
          new_uri.uri_raw = old_u.uri_raw
          new_uri.uri_normalized = old_u.uri_normalized
          new_uri.label = old_u.uri_text
          old_u.uri_text.present? ? new_uri.uri_type = "Link" : new_uri.uri_type = "URL"
          new_uri.created_at = old_u.created_at
          # If there is a guid, we don't want it on both the observable and the indicator, just generate a new one
          new_uri.guid = SecureRandom.uuid
          new_uri.cybox_object_id = SecureRandom.cybox_object_id(new_uri)
          new_uri.save
          print "u".green
        else
          new_uri = r.first
        end
        r = Observable.where(remote_object_id: new_uri.cybox_object_id, remote_object_type: 'Uri')
        obs = nil
        ind = nil
        if r.empty?
          ind,obs,user = create_indicator_and_observable(old_u, new_uri, 'Uri', old_u.uri_raw)
        else
          ind = Indicator.where(stix_id: r.first.stix_indicator_id).first
          print 'oi'.blue
        end
        migrate_indicator(ind, old_u, new_uri)
      end
    end
    puts ""

    puts "DNS Records"
    R5Dns.find_in_batches do |group|
      group.each do |old_d|
        next if old_d.deleted_at.present?
        r = R5Tracking.where(table: "dns_resolution_elements", old_id: old_d.id)
        if r.any?
          print "d".blue
          next
        end
        new_dns = nil
        R5Tracking.create!(table: 'dns_resolution_elements', old_id: old_d.id)
        r = DnsRecord.where(address_value_normalized: old_d.ipv4_address_normalized, domain_normalized: old_d.domain_normalized)
        if r.empty?
          new_dns = DnsRecord.new
          new_dns.guid = SecureRandom.uuid
          new_dns.cybox_object_id = SecureRandom.cybox_object_id(new_dns)
          new_dns.address_value_raw = old_d.ipv4_address_raw
          new_dns.address_value_normalized = old_d.ipv4_address_normalized
          new_dns.domain_raw = old_d.domain_raw
          new_dns.domain_normalized = old_d.domain_normalized
          new_dns.queried_date = old_d.queried_at
          new_dns.created_at = old_d.created_at
          new_dns.updated_at = old_d.updated_at
          new_dns.address_class = old_d.address_class
          new_dns.entry_type = old_d.entry_type
          new_dns.legacy_record_name = old_d.record_name
          new_dns.legacy_record_type = old_d.record_type
          new_dns.legacy_ttl = old_d.ttl
          new_dns.legacy_flags = old_d.flags
          new_dns.legacy_data_length = old_d.data_length
          new_dns.legacy_record_data = old_d.record_data
          new_dns.save
          print "d".green
        else
          new_dns = r.first
        end
        r = Observable.where(remote_object_id: new_dns.cybox_object_id, remote_object_type: 'DnsRecord')
        obs = nil
        ind = nil
        if r.empty?
          ind,obs,user = create_indicator_and_observable(old_d, new_dns, 'DnsRecord', old_d.ipv4_address_raw)
        else
          ind = Indicator.where(stix_id: r.first.stix_indicator_id).first
          print 'oi'.blue
        end
        migrate_indicator(ind, old_d, new_dns)
      end
    end
    puts ""

    puts "Files"
    R5File.find_in_batches do |group|
      group.each do |old_f|
        # Skip deleted entries
        next if old_f.deleted_at.present?
        r = R5Tracking.where(table: "phile_elements", old_id: old_f.id)
        if r.any?
          print "f".blue
          next
        end
        new_phile = nil
        R5Tracking.create!(table: 'phile_elements', old_id: old_f.id)
        r2 = []
        if old_f.md5_normalized.blank?
          r2 = CyboxFile.where(file_name: old_f.file_name)
        else
          r1 = CyboxFileHash.where(hash_type: "MD5",simple_hash_value_normalized: old_f.md5_normalized)
          unless r1.empty?
            r2 = CyboxFile.where(cybox_object_id: r1.first.cybox_file_id,file_name: old_f.file_name)
          end
        end
        if r2.empty?
          new_phile = CyboxFile.new
          new_phile.guid = SecureRandom.uuid
          new_phile.cybox_object_id = SecureRandom.cybox_object_id(new_phile)
          new_phile.file_name = old_f.file_name
          new_phile.file_name_condition = 'Equals'
          new_phile.file_path = old_f.path
          new_phile.file_path_condition = 'Equals'
          new_phile.size_in_bytes = old_f.file_size
          new_phile.size_in_bytes_condition = 'Equals'
          new_phile.legacy_file_type = old_f.file_type
          new_phile.legacy_registry_edits = old_f.registry_edits
          new_phile.legacy_av_signature_mcafee = old_f.av_signature_mcafee
          new_phile.legacy_av_signature_microsoft = old_f.av_signature_microsoft
          new_phile.legacy_av_signature_symantec = old_f.av_signature_symantec
          new_phile.legacy_av_signature_trendmicro = old_f.av_signature_trendmicro
          new_phile.legacy_av_signature_kaspersky = old_f.av_signature_kaspersky
          new_phile.legacy_compiled_at = old_f.compiled_at
          new_phile.legacy_compiler_type = old_f.compiler_type
          new_phile.legacy_cve = old_f.cve
          new_phile.legacy_keywords = old_f.keywords
          new_phile.legacy_mutex = old_f.mutex
          new_phile.legacy_packer = old_f.packer
          new_phile.legacy_xor_key = old_f.xor_key
          new_phile.legacy_motif_name = old_f.motif_name
          new_phile.legacy_motif_size = old_f.motif_size
          new_phile.legacy_composite_hash = old_f.composite_hash
          new_phile.legacy_command_line = old_f.command_line
          new_phile.created_at = old_f.created_at
          new_phile.updated_at = old_f.updated_at
          new_phile.save
          R5Destination.create!(r5table: old_f.class.table_name, r5id: old_f.id, r6table:new_phile.class.table_name, r6id:new_phile.id)
          print "f".green
          fh=CyboxFileHash.new
          fh.cybox_file_id = new_phile.cybox_object_id
          fh.cybox_object_id = SecureRandom.uuid
          fh.hash_type = "MD5"
          fh.simple_hash_value = old_f.md5_raw
          fh.simple_hash_value_normalized = old_f.md5_normalized
          fh.created_at = old_f.created_at
          fh.updated_at = old_f.updated_at
          fh.guid = SecureRandom.uuid
          fh.save
          print "h".green
          unless old_f.sha1_raw.blank?
            fh=CyboxFileHash.new
            fh.cybox_file_id = new_phile.cybox_object_id
            fh.guid = SecureRandom.uuid
            fh.cybox_object_id = SecureRandom.cybox_object_id(fh)
            fh.hash_type = "SHA1"
            fh.simple_hash_value = old_f.sha1_raw
            fh.simple_hash_value_normalized = old_f.sha1_normalized
            fh.created_at = old_f.created_at
            fh.updated_at = old_f.updated_at
            fh.save
            print "h".green
          end
          unless old_f.sha256_raw.blank?
            fh=CyboxFileHash.new
            fh.cybox_file_id = new_phile.cybox_object_id
            fh.guid = SecureRandom.uuid
            fh.cybox_object_id = SecureRandom.cybox_object_id(fh)
            fh.hash_type = "SHA256"
            fh.simple_hash_value = old_f.sha256_raw
            fh.simple_hash_value_normalized = old_f.sha256_normalized
            fh.created_at = old_f.created_at
            fh.updated_at = old_f.updated_at
            fh.save
            print "h".green
          end
          unless old_f.ssdeep.blank?
            fh=CyboxFileHash.new
            fh.cybox_file_id = new_phile.cybox_object_id
            fh.guid = SecureRandom.uuid
            fh.cybox_object_id = SecureRandom.cybox_object_id(fh)
            fh.hash_type = "SSDEEP"
            fh.fuzzy_hash_value = old_f.ssdeep
            fh.fuzzy_hash_value_normalized = old_f.ssdeep.upcase
            fh.created_at = old_f.created_at
            fh.updated_at = old_f.updated_at
            fh.save
            print "h".green
          end
        else
          new_phile = r2.first
        end
        r = Observable.where(remote_object_id: new_phile.cybox_object_id, remote_object_type: 'CyboxFile')
        obs = nil
        ind = nil
        if r.empty?
          ind,obs,user = create_indicator_and_observable(old_f, new_phile, 'CyboxFile', old_f.file_name)
        else
          ind = Indicator.where(stix_id: r.first.stix_indicator_id).first
          R5Destination.create!(r5table: old_f.class.table_name,r5id: old_f.id, r6table:ind.class.table_name, r6id: ind.id)
          print 'oi'.blue
        end
        migrate_indicator(ind, old_f, new_phile)
      end
    end
    puts ""

    puts "Weather Map Data"
    R5WeatherMapData.find_in_batches do |group|
      group.each do |old_d|
        # Skip deleted entries
        next if old_d.deleted_at.present?
        r = R5Tracking.where(table: "weather_map_data", old_id: old_d.id)
        if r.any?
          print "w".blue
          next
        end
        R5Tracking.create!(table: 'weather_map_data', old_id: old_d.id)
        d = WeatherMapData.new
        d.ip_address_raw = old_d.ip_address_raw
        d.ipv4_address_normalized = old_d.ipv4_address_normalized
        d.ipv6_address_normalized = old_d.ipv6_address_normalized
        d.ipv4_address_cybox_hash = old_d.ipv4_address_sun
        d.ipv6_address_cybox_hash = old_d.ipv6_address_sun
        d.ipv4_start = old_d.ipv4_start
        d.ipv4_end = old_d.ipv4_end
        d.iso_country_code = old_d.iso_country_code
        d.com_threat_score = old_d.com_threat_score
        d.gov_threat_score = old_d.gov_threat_score
        d.agencies_sensors_seen_on = old_d.agencies_sensors_seen_on
        d.first_date_seen_raw = old_d.first_date_seen_raw
        d.first_date_seen = old_d.first_date_seen
        d.last_date_seen_raw = old_d.last_date_seen_raw
        d.last_date_seen = old_d.last_date_seen
        d.created_at = old_d.created_at
        d.updated_at = old_d.updated_at
        d.save
        print "w".green
      end
    end
    puts ""

    # depends on user
    puts "Strings (Phrases)"
    R5Phrases.find_in_batches do |group|
      group.each do |old_p|
        # Skip deleted entries
        next if old_p.deleted_at.present?
        r = R5Tracking.where(table: "phrase_elements", old_id: old_p.id)
        if r.any?
          print "p".blue
          next
        end
        R5Tracking.create!(table: 'phrase_elements', old_id: old_p.id)
        new_item = CyboxCustomObject.new
        new_item.guid = SecureRandom.uuid
        new_item.cybox_object_id = SecureRandom.cybox_object_id(new_item)
        new_item.custom_name = "String"
        new_item.string = old_p.string_text_raw
        new_item.string_description = old_p.description
        new_item.cybox_hash = old_p.string_text_sun
        user = nil
        user_id = nil
        user_id ||= old_p.user_id
        user_id ||= old_p.created_by_id
        if user_id.present?
          r_users = User.where(r5_id: user_id)
          if r_users.any?
            user = r_users.first
          end
        end
        new_item.user_guid = user.guid if user.present?
        new_item.created_at = old_p.created_at
        new_item.updated_at = old_p.updated_at
        new_item.save
        R5Destination.create!(r5table: old_p.class.table_name, r5id: old_p.id, r6table:new_item.class.table_name, r6id:new_item.id)
        print "p".green
      end
    end
    puts ""

    # depends on indicators / observables
    puts "Relationships"
    R5Relationship.find_in_batches do |group|
      group.each do |old_r|
        r = R5Tracking.where(table: "relationships", old_id: old_r.id)
        if r.any?
          print "r".blue
          next
        end
        R5Tracking.create!(table: 'relationships', old_id: old_r.id)
        if old_r.left_element_type.blank? || old_r.right_element_type.blank?
          print "r".red
          next
        end
        # r5.relationship
        # "relationship_type"
        # stix_related_objects
        new_rel_1 = StixRelatedObject.new
        dest_ind = nil
        dests = R5Destination.where(r5table: r5_type_to_table(old_r.right_element_type), r5id: old_r.right_element_id, r6table: Indicator.table_name)
        if dests.any?
          dest_ind = Indicator.find(dests.first.r6id)
        end
        src_ind = nil
        srcs = R5Destination.where(r5table: r5_type_to_table(old_r.left_element_type), r5id: old_r.left_element_id, r6table: Indicator.table_name)
        if srcs.any?
          src_ind = Indicator.find(srcs.first.r6id)
        end
        next unless dest_ind.present? && src_ind.present?
        new_rel_1.remote_dest_object_type = Indicator.to_s
        new_rel_1.remote_dest_object_guid = dest_ind.guid
        new_rel_1.remote_src_object_type = Indicator.to_s
        new_rel_1.remote_src_object_guid = src_ind.guid
        new_rel_1.stix_information_source_id = "US-CERT"
        new_rel_1.relationship_type = "Indicator to Indicator"
        new_rel_1.guid = SecureRandom.uuid
        new_rel_1.created_by_user_guid = src_ind.created_by_user_guid
        new_rel_1.updated_by_user_guid = src_ind.updated_by_user_guid
        new_rel_1.created_at = old_r.created_at
        new_rel_1.updated_at = old_r.updated_at
        new_rel_1.save
        new_rel_2 = StixRelatedObject.new
        dest_obs = nil
        dests = R5Destination.where(r5table: r5_type_to_table(old_r.right_element_type), r5id: old_r.right_element_id, r6table: r5type_to_r6model(old_r.right_element_type).table_name)
        if dests.any?
          dest_obs = r5type_to_r6model(old_r.right_element_type).find(dests.first.r6id)
        end
        src_obs = nil
        srcs = R5Destination.where(r5table: r5_type_to_table(old_r.left_element_type), r5id: old_r.left_element_id, r6table: r5type_to_r6model(old_r.left_element_type).table_name)
        if srcs.any?
          src_obs = r5type_to_r6model(old_r.left_element_type).find(srcs.first.r6id)
        end
        next unless dest_obs.present? && src_obs.present?
        new_rel_2.remote_dest_object_type = dest_obs.class.to_s
        new_rel_2.remote_dest_object_guid = dest_obs.guid
        new_rel_2.remote_src_object_type = src_obs.class.to_s
        new_rel_2.remote_src_object_guid = src_ind.guid
        new_rel_2.stix_information_source_id = "US-CERT"
        new_rel_2.relationship_type = old_r.relationship_type
        new_rel_2.guid = SecureRandom.uuid
        new_rel_2.created_by_user_guid = src_ind.created_by_user_guid
        new_rel_2.updated_by_user_guid = src_ind.updated_by_user_guid
        new_rel_2.created_at = old_r.created_at
        new_rel_2.updated_at = old_r.updated_at
        new_rel_2.save
        print "r".green
      end
    end
    puts ""

    # depends on indicators / observables
    puts "Searches"
    R5Search.find_in_batches do |group|
      group.each do |old_s|
        r = R5Tracking.where(table: "searches", old_id: old_s.id)
        if r.any?
          print "s".blue
          next
        end
        R5Tracking.create!(table: 'searches', old_id: old_s.id)
        s = SearchLog.new
        s.query = old_s.query
        user = nil
        user_id = old_s.user_id
        if user_id.present?
          r_users = User.where(r5_id: user_id)
          if r_users.any?
            user = r_users.first
          end
        end
        s.user_guid = user.guid if user.present?
        s.created_at = old_s.created_at
        s.updated_at = old_s.updated_at
        s.save
        print "s".green
      end
    end
    puts ""

    puts "Section Hashes"
    R5SectionHash.find_in_batches do |group|
      group.each do |old_s|
        r = R5Tracking.where(table: "section_hashes", old_id: old_s.id)
        if r.any?
          print "s".blue
          next
        end
        R5Tracking.create!(table: 'section_hashes', old_id: old_s.id)
        s = SectionHash.new
        ind = nil
        inds = R5Destination.where(r5table: R5File.table_name, r5id: old_s.phile_element_id, r6table: Indicator.table_name)
        if inds.any?
          ind = Indicator.find(inds.first.r6id)
        end
        #raise "Can't find indicator corresponding to phile_element_id #{old_s.phile_element_id}" if ind.nil?
        if ind.present?
          s.indicator_guid = ind.guid
        else
          if old_s.old_phile_id.present?
            op2 = R5OldPhiles2.find(old_s.old_phile_id)
            omh = nil
            omh = R5OldMD5Hash.find(op2.md5_hash_id) if op2.md5_hash_id.present?
            rpe = []
            rpe = R5File.where(md5_raw: omh.hsh) if omh.present?
            if rpe.any?
              pe = rpe.first
              inds = R5Destination.where(r5table: R5File.table_name, r5id: pe.id, r6table: Indicator.table_name)
              if inds.any?
                ind = Indicator.find(inds.first.r6id)
                s.indicator_guid = ind.guid
              end
            end
          end
        end
        s.hsh = old_s.hsh
        s.name = old_s.name
        s.ord = old_s.ord
        s.size = old_s.size
        s.hash_type = old_s.hash_type
        s.vsize = old_s.vsize
        s.save
        print "s".green
      end
    end
    puts ""

    puts "Attachments"
    R5Attachment.find_in_batches do |group|
      group.each do |old_a|
        r = R5Tracking.where(table: "attachments", old_id: old_a.id)
        if r.any?
          print "a".blue
          next
        end
        R5Tracking.create!(table: 'attachments', old_id: old_a.id)
        inds = R5Destination.where(r5table: R5Sighting.table_name, r5id: old_a.container_id, r6table: Indicator.table_name)
        raise "Can't find any indicators indicator corresponding to sighting id #{old_a.container_id}" if inds.empty?
        inds.each do |r5dest|
          ind = Indicator.find(r5dest.r6id)
          u = UploadedFile.new
          u.is_attachment = true
          u.file_name = old_a.filename
          u.file_size = old_a.data.bytesize if old_a.data.present?
          u.status = 'S'
          u.validate_only = false
          u.user_guid = ind.created_by_user_guid
          u.created_at = old_a.created_at
          u.updated_at = old_a.updated_at
          u.guid = SecureRandom.uuid
          u.save!
          o = OriginalInput.new
          o.is_attachment = true
          o.mime_type = old_a.mime_type
          o.raw_content = old_a.data.encode("BINARY")
          o.uploaded_file_id = u.id
          o.created_at = old_a.created_at
          o.updated_at = old_a.updated_at
          o.guid = SecureRandom.uuid
          o.remote_object_id = ind.stix_id
          o.remote_object_type = Indicator.to_s
          o.save
          print "o".green
        end
      end
    end
    puts ""

    puts "Yara Rules"
    R5YaraRule.find_in_batches do |group|
      group.each do |old_y|
        r = R5Tracking.where(table: "yara_rules", old_id: old_y.id)
        if r.any?
          print "y".blue
          next
        end
        R5Tracking.create!(table: 'yara_rules', old_id: old_y.id)
        y = YaraRule.new
        y.name = old_y.name
        y.string = old_y.string
        y.string_location = old_y.string_location
        y.rule = old_y.rule
        ind = nil
        inds = R5Destination.where(r5table: R5File.table_name, r5id: old_y.phile_element_id, r6table: Indicator.table_name)
        raise "Can't find indicator corresponding to phile_element_id #{old_y.phile_element_id}" if inds.empty?
        ind = Indicator.find(inds.first.r6id)
        y.indicator_guid = ind.guid
        y.save
        print "y".green
      end
    end
    puts ""

    puts "Migration Complete"
    puts ""
  end
end
