class FixOldCiscpTags < ActiveRecord::Migration
  class MPackage < ActiveRecord::Base; self.table_name = 'stix_packages'; end

  class MIndicator < ActiveRecord::Base
    self.table_name = 'stix_indicators'
    has_many :indicators_packages, primary_key: :stix_id, foreign_key: :stix_indicator_id
    has_many :stix_packages, through: :indicators_packages
  end

  class MExploitTarget < ActiveRecord::Base
    self.table_name = 'exploit_targets'
    has_many :exploit_target_packages, primary_key: :stix_id, foreign_key: :stix_exploit_target_id
    has_many :stix_packages, through: :exploit_target_packages
    has_many :ttp_exploit_targets, primary_key: :stix_id, foreign_key: :stix_exploit_target_id
    has_many :ttps, through: :ttp_exploit_targets
  end

  class MVulnerability < ActiveRecord::Base
    self.table_name = 'vulnerabilities'
    has_many :exploit_target_vulnerabilities, primary_key: :guid, foreign_key: :vulnerability_guid
    has_many :exploit_targets, through: :exploit_target_vulnerabilities
    has_many :stix_packages, through: :exploit_targets
  end

  class MIndicatorTtp < ActiveRecord::Base
    self.table_name = "indicator_ttps"
    belongs_to :m_indicator, primary_key: :stix_id, foreign_key: :stix_indicator_id
    belongs_to :m_ttp, primary_key: :stix_id, foreign_key: :stix_ttp_id
  end

  class MTtp < ActiveRecord::Base
    self.table_name = 'ttps'
    has_many :ttp_packages, primary_key: :stix_id, foreign_key: :stix_ttp_id
    has_many :stix_packages, through: :ttp_packages
    has_many :m_indicator_ttps, primary_key: :stix_id, foreign_key: :stix_ttp_id
    has_many :m_indicators, through: :m_indicator_ttps
  end

  class MAttackPattern < ActiveRecord::Base
    self.table_name = 'attack_patterns'
    has_many :ttp_attack_patterns, primary_key: :stix_id, foreign_key: :stix_attack_pattern_id
    has_many :ttps, through: :ttp_attack_patterns
    has_many :stix_packages, through: :ttps
  end

  class MIndicatorsCourseOfAction < ActiveRecord::Base
    self.table_name = 'indicators_course_of_actions'
    belongs_to :m_course_of_action, primary_key: :stix_id, foreign_key: :course_of_action_id, touch: true
    belongs_to :m_indicator, primary_key: :stix_id, foreign_key: :stix_indicator_id, touch: true
  end

  class MCourseOfAction < ActiveRecord::Base
    self.table_name = 'course_of_actions'
    has_many :packages_course_of_actions, primary_key: :stix_id, foreign_key: :course_of_action_id
    has_many :stix_packages, through: :packages_course_of_actions
    has_many :m_indicators_course_of_actions, primary_key: :stix_id, foreign_key: :course_of_action_id
    has_many :m_indicators, through: :m_indicators_course_of_actions
    has_many :exploit_target_course_of_actions, primary_key: :stix_id, foreign_key: :stix_course_of_action_id, dependent: :destroy
    has_many :exploit_targets, through: :exploit_target_course_of_actions
  end
  
  class MObservable < ActiveRecord::Base
    self.table_name = 'cybox_observables'
    belongs_to :m_indicator, primary_key: :stix_id, foreign_key: :stix_indicator_id, touch: true
    belongs_to :object, polymorphic: true, primary_key: :cybox_object_id, foreign_key: :remote_object_id, foreign_type: :remote_object_type, touch: true

    belongs_to :m_dns_record, primary_key: :cybox_object_id, class_name: 'DnsRecord', foreign_key: :remote_object_id, touch: true
    belongs_to :m_dns_query, primary_key: :cybox_object_id, class_name: 'DnsQuery', foreign_key: :remote_object_id, touch: true
    belongs_to :m_domain, primary_key: :cybox_object_id, class_name: 'Domain', foreign_key: :remote_object_id, touch: true
    belongs_to :m_hostname, primary_key: :cybox_object_id, class_name: 'Hostname', foreign_key: :remote_object_id, touch: true
    belongs_to :m_email_message, primary_key: :cybox_object_id, class_name: 'EmailMessage', foreign_key: :remote_object_id, touch: true
    belongs_to :m_file, primary_key: :cybox_object_id, class_name: 'CyboxFile', foreign_key: :remote_object_id, touch: true
    belongs_to :m_http_session, primary_key: :cybox_object_id, class_name: 'HttpSession', foreign_key: :remote_object_id, touch: true
    belongs_to :m_address, primary_key: :cybox_object_id, class_name: 'Address', foreign_key: :remote_object_id, touch: true
    belongs_to :m_link, primary_key: :cybox_object_id, class_name: 'Link', foreign_key: :remote_object_id, touch: true
    belongs_to :m_mutex, primary_key: :cybox_object_id, class_name: 'CyboxMutex', foreign_key: :remote_object_id, touch: true
    belongs_to :m_network_connection, primary_key: :cybox_object_id, class_name: 'NetworkConnection', foreign_key: :remote_object_id, touch: true
    belongs_to :m_registry, primary_key: :cybox_object_id, class_name: 'Registry', foreign_key: :remote_object_id, touch: true
    belongs_to :m_socket_address, primary_key: :cybox_object_id, class_name: 'SocketAddress', foreign_key: :remote_object_id, touch: true
    belongs_to :m_uri, primary_key: :cybox_object_id, class_name: 'Uri', foreign_key: :remote_object_id, touch: true
    belongs_to :m_port, primary_key: :cybox_object_id, class_name: 'Port', foreign_key: :remote_object_id, touch: true
  end  

  class MAddress < ActiveRecord::Base
    self.table_name = 'cybox_addresses'
    has_many :m_observables, primary_key: :cybox_object_id, foreign_key: :remote_object_id
    has_many :m_indicators, through: :m_observables
    has_many :stix_packages, through: :m_indicators

    has_many :email_senders, class_name: 'EmailMessage', primary_key: :cybox_object_id, foreign_key: :sender_cybox_object_id
    has_many :email_reply_tos, class_name: 'EmailMessage', primary_key: :cybox_object_id, foreign_key: :reply_to_cybox_object_id
    has_many :email_froms, class_name: 'EmailMessage', primary_key: :cybox_object_id, foreign_key: :from_cybox_object_id
    has_many :email_x_ips, class_name: 'EmailMessage', primary_key: :cybox_object_id, foreign_key: :x_ip_cybox_object_id

    has_many :socket_address_addresses, primary_key: :cybox_object_id, foreign_key: :address_id
    has_many :socket_addresses, through: :socket_address_addresses

    has_many :dns_records, class_name: 'DnsRecord', primary_key: :cybox_object_id, foreign_key: :address_cybox_object_id
  end

  class MDnsQuery < ActiveRecord::Base
    self.table_name = 'cybox_dns_queries'
    has_many :m_observables, primary_key: :cybox_object_id, foreign_key: :remote_object_id
    has_many :m_indicators, through: :m_observables
    has_many :stix_packages, through: :m_indicators

    has_many :layer_seven_connection_dns_queries, primary_key: :cybox_object_id, foreign_key: :dns_query_id
    has_many :layer_seven_connections, through: :layer_seven_connection_dns_queries
    has_many :network_connections, through: :layer_seven_connections
  end

  class MResourceRecord < ActiveRecord::Base
    self.table_name = "resource_records"
    has_many :dns_query_resource_records, primary_key: :guid, foreign_key: :resource_record_id
    has_many :dns_queries, through: :dns_query_resource_records
  end

  class MDnsRecord < ActiveRecord::Base
    self.table_name = 'cybox_dns_records'
    has_many :m_observables, primary_key: :cybox_object_id, foreign_key: :remote_object_id
    has_many :m_indicators, through: :m_observables
    has_many :stix_packages, through: :m_indicators

    has_many :resource_record_dns_records, primary_key: :cybox_object_id, foreign_key: :dns_record_id
    has_many :resource_records, through: :resource_record_dns_records
  end

  class MDomain < ActiveRecord::Base
    self.table_name = 'cybox_domains'
    has_many :m_observables, primary_key: :cybox_object_id, foreign_key: :remote_object_id
    has_many :m_indicators, through: :m_observables
    has_many :stix_packages, through: :m_indicators

    has_many :dns_records, class_name: 'DnsRecord', primary_key: :cybox_object_id, foreign_key: :domain_cybox_object_id
  end

  class MEmailMessage < ActiveRecord::Base
    self.table_name = 'cybox_email_messages'
    has_many :m_observables, primary_key: :cybox_object_id, foreign_key: :remote_object_id
    has_many :m_indicators, through: :m_observables
    has_many :stix_packages, through: :m_indicators
  end

  class MFile < ActiveRecord::Base
    self.table_name = 'cybox_files'
    has_many :m_observables, primary_key: :cybox_object_id, foreign_key: :remote_object_id
    has_many :m_indicators, through: :m_observables
    has_many :stix_packages, through: :m_indicators

    has_many :email_files, primary_key: :guid, foreign_key: :cybox_file_id
    has_many :email_messages, through: :email_files
  end

  class MFileHash < ActiveRecord::Base
    self.table_name = "cybox_file_hashes"
    belongs_to :file,  class_name: 'CyboxFile', primary_key: :cybox_object_id, foreign_key: :cybox_file_id
  end

  class MHostname < ActiveRecord::Base
    self.table_name = 'cybox_hostnames'
    has_many :m_observables, primary_key: :cybox_object_id, foreign_key: :remote_object_id
    has_many :m_indicators, through: :m_observables
    has_many :stix_packages, through: :m_indicators

    has_many :socket_address_hostnames, primary_key: :cybox_object_id, foreign_key: :hostname_id
    has_many :socket_addresses, through: :socket_address_hostnames
  end

  class MHttpSession < ActiveRecord::Base
    self.table_name = 'cybox_http_sessions'
    has_many :m_observables, primary_key: :cybox_object_id, foreign_key: :remote_object_id
    has_many :m_indicators, through: :m_observables
    has_many :stix_packages, through: :m_indicators
    
    has_many :layer_seven_connections, class_name: 'LayerSevenConnection', primary_key: :cybox_object_id, foreign_key: :http_session_id
    has_many :network_connections, through: :layer_seven_connections
  end

  class MLink < ActiveRecord::Base
    self.table_name = 'cybox_links'
    has_many :m_observables, primary_key: :cybox_object_id, foreign_key: :remote_object_id
    has_many :m_indicators, through: :m_observables
    has_many :stix_packages, through: :m_indicators

    has_many :email_links, primary_key: :id, foreign_key: :link_id
    has_many :email_messages, through: :email_links
  end

  class MMutex < ActiveRecord::Base
    self.table_name = 'cybox_mutexes'
    has_many :m_observables, primary_key: :cybox_object_id, foreign_key: :remote_object_id
    has_many :m_indicators, through: :m_observables
    has_many :stix_packages, through: :m_indicators
  end

  class MNetworkConnection < ActiveRecord::Base
    self.table_name = 'cybox_network_connections'
    has_many :m_observables, primary_key: :cybox_object_id, foreign_key: :remote_object_id
    has_many :m_indicators, through: :m_observables
    has_many :stix_packages, through: :m_indicators
  end

  class MPort < ActiveRecord::Base
    self.table_name = 'cybox_ports'
    has_many :m_observables, primary_key: :cybox_object_id, foreign_key: :remote_object_id
    has_many :m_indicators, through: :m_observables
    has_many :stix_packages, through: :m_indicators

    has_many :socket_address_ports, primary_key: :cybox_object_id, foreign_key: :port_id
    has_many :socket_addresses, through: :socket_address_ports
  end

  class MRegistry < ActiveRecord::Base
    self.table_name = 'cybox_win_registry_keys'
    has_many :m_observables, primary_key: :cybox_object_id, foreign_key: :remote_object_id
    has_many :m_indicators, through: :m_observables
    has_many :stix_packages, through: :m_indicators
  end

  class MSocketAddress < ActiveRecord::Base
    self.table_name = 'cybox_socket_addresses'
    has_many :m_observables, primary_key: :cybox_object_id, foreign_key: :remote_object_id
    has_many :m_indicators, through: :m_observables
    has_many :stix_packages, through: :m_indicators

    has_many :network_connection_sources, class_name: 'NetworkConnection', primary_key: :cybox_object_id, foreign_key: :source_socket_address_id
    has_many :network_connection_destinations, class_name: 'NetworkConnection', primary_key: :cybox_object_id, foreign_key: :dest_socket_address_id
  end

  class MQuestion < ActiveRecord::Base
    self.table_name = "questions"
    has_many :dns_query_questions, primary_key: :guid, foreign_key: :question_id
    has_many :dns_queries, through: :dns_query_questions
  end

  class MUri < ActiveRecord::Base
    self.table_name = 'cybox_uris'
    has_many :m_observables, primary_key: :cybox_object_id, foreign_key: :remote_object_id
    has_many :m_indicators, through: :m_observables
    has_many :stix_packages, through: :m_indicators

    has_many :links, primary_key: :cybox_object_id, foreign_key: :uri_object_id

    has_many :question_uris, primary_key: :cybox_object_id, foreign_key: :uri_id
    has_many :questions, through: :question_uris

    has_many :email_uris, primary_key: :id, foreign_key: :uri_id
    has_many :email_messages, through: :email_uris
  end
  
  def up
    if ActiveRecord::Base.connection.instance_values["config"][:adapter] == 'sqlite3'
      migrate_data("stix_packages.title REGEXP '\\A(?:(?:MAR|MIFR|JIB|JAR)-.*|(?:IB|AR)-\\d{2}-[12]0\\d{3})'", :is_ciscp, true, 1)
    else
      # This should be oracle on production/int servers.
      migrate_data("regexp_like(stix_packages.title, '\\A(?(?MAR|MIFR|JIB|JAR)-.*|(?AR|IB)-[0-9]{2}-[12]0[0-9]{3})')", :is_ciscp, true, 1)
    end
  end

  def down
    if ActiveRecord::Base.connection.instance_values["config"][:adapter] == 'sqlite3'
      migrate_data("stix_packages.title REGEXP '\\A(?:(?:MAR|MIFR|JIB|JAR)-.*|(?:IB|AR)-\\d{2}-[12]0\\d{3})'", :is_ciscp, false, 1)
    else
      # This should be oracle on production/int servers.
      migrate_data("regexp_like(stix_packages.title, '\\A(?(?MAR|MIFR|JIB|JAR)-.*|(?AR|IB)-[0-9]{2}-[12]0[0-9]{3})')", :is_ciscp, false, 1)
    end
  end
  
  def migrate_data(where_exp, column, migration_direction, delay)
    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)
    ActiveRecord::Base.record_timestamps = false

    stix_objects = ["FixOldCiscpTags::MIndicator", "FixOldCiscpTags::MExploitTarget", "FixOldCiscpTags::MTtp", "FixOldCiscpTags::MCourseOfAction"]

    cybox_objects = ["FixOldCiscpTags::MAddress", "FixOldCiscpTags::MDnsQuery", "FixOldCiscpTags::MDnsRecord", "FixOldCiscpTags::MDomain", "FixOldCiscpTags::MEmailMessage", "FixOldCiscpTags::MFile", "FixOldCiscpTags::MHostname", "FixOldCiscpTags::MHttpSession", "FixOldCiscpTags::MLink", "FixOldCiscpTags::MMutex", "FixOldCiscpTags::MNetworkConnection", "FixOldCiscpTags::MPort", "FixOldCiscpTags::MRegistry", "FixOldCiscpTags::MSocketAddress", "FixOldCiscpTags::MUri"]

    cybox_objects_sas = ["FixOldCiscpTags::MAddress", "FixOldCiscpTags::MPort", "FixOldCiscpTags::MHostname"]

    cybox_object_dns_r = ["FixOldCiscpTags::MAddress", "FixOldCiscpTags::MDomain"]

    cybox_object_dns_q = ["FixOldCiscpTags::MQuestion", "FixOldCiscpTags::MResourceRecord"]

    puts "\nThis Migration will be processing multiple tables and may take a while.\n"
    puts "\nTransitioning Stix Packages First.\n"
    sleep delay.seconds

    begin
      total_groups = MPackage.where(where_exp).where(column => !migration_direction).count / 1000
      MPackage.where(where_exp).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
        puts "Processing group ##{batch+1} of #{total_groups+1}"
        group.each do |object|
          object[column] = migration_direction
          begin
            object.save!
          rescue Exception => e
            puts "Could not transition #{object.id}, skipping Package. Error: #{e.to_s}"
          end
        end
      end

      puts "\nTransitioning Stix Objects.\n"
      sleep delay.seconds

      stix_objects.each do |x|
        total_groups = x.constantize.joins(:stix_packages).where("stix_packages.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
        x.constantize.joins(:stix_packages).where("stix_packages.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
          puts "Processing group ##{batch+1} of #{total_groups+1}"
          group.each do |object|
            object[column] = migration_direction
            begin
              object.save!
            rescue Exception => e
              puts "Could not transition #{object.id}, skipping #{x[1..x.length]}. Error: #{e.to_s}"
            end
          end
        end
      end

      puts "\nHandling Special cases.\n"
      sleep delay.seconds

      total_groups = MTtp.joins(:m_indicators).where("stix_indicators.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
      MTtp.joins(:m_indicators).where("stix_indicators.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
        puts "Processing group ##{batch+1} of #{total_groups+1}"
        group.each do |object|
          object[column] = migration_direction
          begin
            object.save!
          rescue Exception => e
            puts "Could not transition #{object.id}, skipping Ttp. Error: #{e.to_s}"
          end
        end
      end

      total_groups = MExploitTarget.joins(:ttps).where("ttps.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
      MExploitTarget.joins(:ttps).where("ttps.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
        puts "Processing group ##{batch+1} of #{total_groups+1}"
        group.each do |object|
          object[column] = migration_direction
          begin
            object.save!
          rescue Exception => e
            puts "Could not transition #{object.id}, skipping Exploit Target. Error: #{e.to_s}"
          end
        end
      end

      total_groups = MCourseOfAction.joins(:m_indicators).where("stix_indicators.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
      MCourseOfAction.joins(:m_indicators).where("stix_indicators.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
        puts "Processing group ##{batch+1} of #{total_groups+1}"
        group.each do |object|
          object[column] = migration_direction
          begin
            object.save!
          rescue Exception => e
            puts "Could not transition #{object.id}, skipping Course of Action. Error: #{e.to_s}"
          end
        end
      end

      total_groups = MCourseOfAction.joins(:exploit_targets).where("exploit_targets.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
      MCourseOfAction.joins(:exploit_targets).where("exploit_targets.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
        puts "Processing group ##{batch+1} of #{total_groups+1}"
        group.each do |object|
          object[column] = migration_direction
          begin
            object.save!
          rescue Exception => e
            puts "Could not transition #{object.id}, skipping Course of Action. Error: #{e.to_s}"
          end
        end
      end

      total_groups = MVulnerability.joins(:exploit_targets).where("exploit_targets.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
      MVulnerability.joins(:exploit_targets).where("exploit_targets.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
        puts "Processing group ##{batch+1} of #{total_groups+1}"
        group.each do |object|
          object[column] = migration_direction
          begin
            object.save!
          rescue Exception => e
            puts "Could not transition #{object.id}, skipping Vulnerability. Error: #{e.to_s}"
          end
        end
      end

      total_groups = MAttackPattern.joins(:ttps).where("ttps.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
      MAttackPattern.joins(:ttps).where("ttps.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
        puts "Processing group ##{batch+1} of #{total_groups+1}"
        group.each do |object|
          object[column] = migration_direction
          begin
            object.save!
          rescue Exception => e
            puts "Could not transition #{object.id}, skipping Vulnerability. Error: #{e.to_s}"
          end
        end
      end

      puts "\nFinished transitioning STIX Objects. Transitioning CYBOX Objects now.\n"
      sleep delay.seconds

      cybox_objects.each do |x|
        total_groups = x.constantize.joins(:m_observables).joins(:m_indicators).joins(:stix_packages).where("stix_packages.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
        x.constantize.joins(:m_observables).joins(:m_indicators).joins(:stix_packages).where("stix_packages.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
          puts "Processing group ##{batch+1} of #{total_groups+1}"
          group.each do |object|
            object[column] = migration_direction
            begin
              object.save!
            rescue Exception => e
              puts "Could not transition #{object.id}, skipping #{x[1..x.length]}. Error: #{e.to_s}"
            end
          end
        end
      end

      puts "\nFinished transitioning CYBOX Objects. Handling Special Cases.\n"
      sleep delay.seconds

      email_fields = [:email_senders, :email_reply_tos, :email_froms, :email_x_ips]

      email_fields.each do |x|
        total_groups = MAddress.joins(x).where("cybox_email_messages.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
        MAddress.joins(x).where("cybox_email_messages.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
          puts "Processing group ##{batch+1} of #{total_groups+1}"
          group.each do |object|
            object[column] = migration_direction
            begin
              object.save!
            rescue Exception => e
              puts "Could not transition #{object.id}, skipping #{x[1..x.length]}. Error: #{e.to_s}"
            end
          end
        end
      end

      socket_addresses_fields = [:network_connection_sources, :network_connection_destinations]

      socket_addresses_fields.each do |x|
        total_groups = MSocketAddress.joins(x).where("cybox_network_connections.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
        MSocketAddress.joins(x).where("cybox_network_connections.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
          puts "Processing group ##{batch+1} of #{total_groups+1}"
          group.each do |object|
            object[column] = migration_direction
            begin
              object.save!
            rescue Exception => e
              puts "Could not transition #{object.id}, skipping #{x[1..x.length]}. Error: #{e.to_s}"
            end
          end
        end
      end

      total_groups = MDnsQuery.joins(:network_connections).where("cybox_network_connections.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
      MDnsQuery.joins(:network_connections).where("cybox_network_connections.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
        puts "Processing group ##{batch+1} of #{total_groups+1}"
        group.each do |object|
          object[column] = migration_direction
          begin
            object.save!
          rescue Exception => e
            puts "Could not transition #{object.id}, skipping Object. Error: #{e.to_s}"
          end
        end
      end

      total_groups = MHttpSession.joins(:network_connections).where("cybox_network_connections.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
      MHttpSession.joins(:network_connections).where("cybox_network_connections.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
        puts "Processing group ##{batch+1} of #{total_groups+1}"
        group.each do |object|
          object[column] = migration_direction
          begin
            object.save!
          rescue Exception => e
            puts "Could not transition #{object.id}, skipping Object. Error: #{e.to_s}"
          end
        end
      end

      cybox_object_dns_q.each do |x|
        total_groups = x.constantize.joins(:dns_queries).where("cybox_dns_queries.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
        x.constantize.joins(:dns_queries).where("cybox_dns_queries.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
          puts "Processing group ##{batch+1} of #{total_groups+1}"
          group.each do |object|
            object[column] = migration_direction
            begin
              object.save!
            rescue Exception => e
              puts "Could not transition #{object.id}, skipping Object. Error: #{e.to_s}"
            end
          end
        end
      end

      total_groups = MDnsRecord.joins(:resource_records).where("resource_records.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
      MDnsRecord.joins(:resource_records).where("resource_records.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
        puts "Processing group ##{batch+1} of #{total_groups+1}"
        group.each do |object|
          object[column] = migration_direction
          begin
            object.save!
          rescue Exception => e
            puts "Could not transition #{object.id}, skipping Object. Error: #{e.to_s}"
          end
        end
      end

      cybox_object_dns_r.each do |x|
        total_groups = x.constantize.joins(:dns_records).where("cybox_dns_records.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
        x.constantize.joins(:dns_records).where("cybox_dns_records.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
          puts "Processing group ##{batch+1} of #{total_groups+1}"
          group.each do |object|
            object[column] = migration_direction
            begin
              object.save!
            rescue Exception => e
              puts "Could not transition #{object.id}, skipping Object. Error: #{e.to_s}"
            end
          end
        end
      end

      cybox_objects_sas.each do |x|
        total_groups = x.constantize.joins(:socket_addresses).where("cybox_socket_addresses.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
        x.constantize.joins(:socket_addresses).where("cybox_socket_addresses.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
          puts "Processing group ##{batch+1} of #{total_groups+1}"
          group.each do |object|
            object[column] = migration_direction
            begin
              object.save!
            rescue Exception => e
              puts "Could not transition #{object.id}, skipping Object. Error: #{e.to_s}"
            end
          end
        end
      end

      total_groups = MLink.joins(:email_messages).where("cybox_email_messages.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
      MLink.joins(:email_messages).where("cybox_email_messages.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
        puts "Processing group ##{batch+1} of #{total_groups+1}"
        group.each do |object|
          object[column] = migration_direction
          begin
            object.save!
          rescue Exception => e
            puts "Could not transition #{object.id}, skipping Object. Error: #{e.to_s}"
          end
        end
      end

      total_groups = MUri.joins(:links).where("cybox_links.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
      MUri.joins(:links).where("cybox_links.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
        puts "Processing group ##{batch+1} of #{total_groups+1}"
        group.each do |object|
          object[column] = migration_direction
          begin
            object.save!
          rescue Exception => e
            puts "Could not transition #{object.id}, skipping Object. Error: #{e.to_s}"
          end
        end
      end

      total_groups = MUri.joins(:questions).where("questions.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
      MUri.joins(:questions).where("questions.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
        puts "Processing group ##{batch+1} of #{total_groups+1}"
        group.each do |object|
          object[column] = migration_direction
          begin
            object.save!
          rescue Exception => e
            puts "Could not transition #{object.id}, skipping Object. Error: #{e.to_s}"
          end
        end
      end

      total_groups = MUri.joins(:email_messages).where("cybox_email_messages.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
      MUri.joins(:email_messages).where("cybox_email_messages.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
        puts "Processing group ##{batch+1} of #{total_groups+1}"
        group.each do |object|
          object[column] = migration_direction
          begin
            object.save!
          rescue Exception => e
            puts "Could not transition #{object.id}, skipping Object. Error: #{e.to_s}"
          end
        end
      end

      total_groups = MFile.joins(:email_messages).where("cybox_email_messages.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
      MFile.joins(:email_messages).where("cybox_email_messages.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
        puts "Processing group ##{batch+1} of #{total_groups+1}"
        group.each do |object|
          object[column] = migration_direction
          begin
            object.save!
          rescue Exception => e
            puts "Could not transition #{object.id}, skipping Object. Error: #{e.to_s}"
          end
        end
      end

      total_groups = MFileHash.joins(:file).where("cybox_files.#{column}" => migration_direction).where(column => !migration_direction).count / 1000
      MFileHash.joins(:file).where("cybox_files.#{column}" => migration_direction).where(column => !migration_direction).find_in_batches.with_index do |group, batch|
        puts "Processing group ##{batch+1} of #{total_groups+1}"
        group.each do |object|
          object[column] = migration_direction
          begin
            object.save!
          rescue Exception => e
            puts "Could not transition #{object.id}, skipping Object. Error: #{e.to_s}"
          end
        end
      end
    ensure
      ActiveRecord::Base.record_timestamps = true
    end

    ::Sunspot.session = ::Sunspot.session.original_session
  end

end
