# Helper class for passing Indicator observables
module IndicatorHelper
  include StixMarkingHelper

  # Writes out the observable values for indicators.
  def writeObservables indicator

    value = ""
    observable = indicator.observables.first
    unless observable.nil?
      type = observable.remote_object_type
      if indicator.observable_value.present?
        return indicator.observable_value
      elsif !type.nil?
        # Email Message
        if type == "EmailMessage"
          names = ["Subject"]
          attributes= ["subject"]
          if User.has_permission(User.current_user,"view_pii_fields")
            names.push("Sender","Reply-To","From")
            attributes.push("sender_normalized","reply_to_normalized","from_normalized")
          end

          value = "";
          (names.length-1).downto(0) { |i|
            if !observable.email_message[attributes[i]].nil?
              if value.length>0
                value << " | "
              end
              value << names[i] + ": " + observable.email_message[attributes[i]]
            end
          }

        # Address
        elsif type == "Address"
          value << "Address: " + observable.address.address.to_s

        # DNS Record
        elsif type == "DnsRecord"
          value << "Address: " + observable.dns_record.address + " | "
          value << "Address Class: " + observable.dns_record.address_class + " | "
          value << "Domain: " + observable.dns_record.domain + " | "
          value << "Entry Type: " + observable.dns_record.entry_type

        # Domain
        elsif type == "Domain"
          value << "Domain Name: " + observable.domain.name
          value << " | Domain Name Condition: " + observable.domain.name_condition

        # Cybox File
        elsif type == "CyboxFile"
          if !observable.file.file_name.nil?
            value << "File Name: " + observable.file.file_name
          end
          if !observable.file.md5.nil? && observable.file.md5.length>0
            if value.length>0
              value << " | "
            end
            value << "MD5: " + observable.file.md5
          end

        # HttpSession
        elsif type == "HttpSession"
          if !observable.http_session.user_agent.nil?
            value << "User Agent: " + observable.http_session.user_agent
          end
          if !observable.http_session.domain_name.nil?
            value << "| Domain Name: " + observable.http_session.domain_name
            if !observable.http_session.port.nil?
              value << ":" + observable.http_session.port
            end
          end
          if !observable.http_session.referer.nil?
            value << "| Referer: " + observable.http_session.referer
          end
          if !observable.http_session.pragma.nil?
            value << "| Pragma: " + observable.http_session.pragma
          end

        # Link
        elsif type == "Link"
          value << "Link: " + observable.link.uri.uri
          value << ' "' + observable.link.label + '"'

        # Cybox Mutex
        elsif type == "CyboxMutex"
          value << "Mutex: " + observable.mutex.name.to_s

        # Network Connection
        elsif type == "NetworkConnection"
          if !observable.network_connection.source_socket_address.nil? or
             !observable.network_connection.source_socket_hostname.nil? or
             !observable.network_connection.source_socket_port.nil?
            value << "Source: "

            if observable.network_connection.source_socket_address.present?
              value << observable.network_connection.source_socket_address
              if observable.network_connection.source_socket_is_spoofed
                value << " (Spoofed)"
              end
            elsif !observable.network_connection.source_socket_hostname.nil?
              value << observable.network_connection.source_socket_hostname
            end
            if observable.network_connection.source_socket_port.present?
              value << ":" + observable.network_connection.source_socket_port
            end
            if observable.network_connection.layer4_protocol.present?
              value << "/" + observable.network_connection.layer4_protocol
            end

            value << " | "
          end

          value << "Destination: "
          if !observable.network_connection.dest_socket_address.nil?
            value << observable.network_connection.dest_socket_address
            if observable.network_connection.dest_socket_is_spoofed
              value << " (Spoofed)"
            end
          elsif !observable.network_connection.dest_socket_hostname.nil?
            value << observable.network_connection.dest_socket_hostname
          end
          if !observable.network_connection.dest_socket_port.nil?
            value << ":" + observable.network_connection.dest_socket_port
          end
          if observable.network_connection.layer4_protocol.present?
            value << "/" + observable.network_connection.layer4_protocol
          end

        # Registry
        elsif type == "Registry"
          value << "Hive: " + observable.registry.hive.to_s + " | Key: " + observable.registry.key.to_s

        # Uri
        elsif type == "Uri"
          value << "Uri: " + observable.uri.uri
        end
      end
    end
    return value
  end


  #For building Indicators in STIX that somehow have multiple observables
  def stix_indicator_multi_observable(indicators)
    malformed_indicators = indicators.select {|i| i.observables.count > 1 }
    return indicators unless malformed_indicators.present?

    malformed_indicators.each do |indicator|
      indicator.observables.each_with_index do |obs,index|
        next if index == 0
        new_indicator = indicator.dup
        new_indicator.guid = SecureRandom.uuid
        new_indicator.stix_id = SecureRandom.stix_id(new_indicator)
        new_indicator.observables = [obs]
        indicators << new_indicator
      end
    end

    indicators
  end

  #Add related indicators to the indicators array to build out in STIX
  def stix_indicator_parse_relationships(indicators)
    indicators_with_related = indicators |
        indicators.collect(&:related_to_objects).flatten.select { |r|
          r.relationship_type == 'Indicator to Indicator'
        }.collect(&:remote_dest_object) |
        indicators.collect(&:related_by_objects).flatten.select { |r|
          r.relationship_type == 'Indicator to Indicator'
        }.collect(&:remote_src_object)

    indicators_with_related.compact.uniq(&:stix_id)
  end
end
