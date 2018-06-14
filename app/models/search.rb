class Search
  class << self
    def indicator_search(q,params = {})
      # Log query that needs to run against the search engine
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      network = nil
      broadcast = nil

      begin
        IPAddr.new(q.to_s)
        ip = IPAddress(q.to_s)
        if ip.class == IPAddress::IPv4
          network = ip.network.to_u32
          broadcast = ip.broadcast.to_u32
        end
      rescue ArgumentError, NoMethodError => e
        ip = nil
        network = nil
        broadcast = nil
      end

      Indicator.search do
        if ip.present? && network.present? && broadcast.present?   #Valid IPv4, Perform Integer based Range Search
          all_of do
            any_of do
              with(:ip_start).greater_than(network)
              with(:ip_start).equal_to(network)
            end
            any_of do
              with(:ip_end).less_than(broadcast)
              with(:ip_end).equal_to(broadcast)
            end
          end
        else
          fulltext q
        end

        if params[:is_ais].present? && params[:is_ais] == true
          with(:is_ais, params[:is_ais]) 
        end
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end

        if params[:observable_type].present?
          fulltext params[:observable_type], :fields => :observable_type
        end

        if params[:ebt] && params[:iet]
          with(:updated_at,params[:ebt]..params[:iet])
        end
        if params[:indicator_type].present?
          with(:indicator_type, params[:indicator_type]) 
        end
        if params[:system_tag_id].present?
          with(:system_tag_id,params[:system_tag_id])
        end
        if params[:exclude_weather_map].present? && params[:exclude_weather_map].to_bool
          with(:from_weather_map,false)
        end
        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
        data_accessor_for(Indicator).include = [:official_confidence,:confidences,observables: [:address,{file: :file_hashes},:mutex,
                                                               :dns_record,:domain,:email_message,:http_session,:link, :hostname, :port,
                                                               :network_connection,{registry: :registry_values},
                                                               :uri],related_to_objects: :confidences,related_by_objects: :confidences,stix_markings: [:isa_marking_structure,:tlp_marking_structure,:simple_marking_structure,{isa_assertion_structure: :isa_privs}]]
      end
    end

    def indicator_filter_search(params = {})
      # Log query that needs to run against the search engine
      query = ""
      query += "title_q: #{params[:title_q]}, " if params[:title_q].present?
      query += "reference_q: #{params[:reference_q]}, " if params[:reference_q].present?
      query += "observable_q: #{params[:observable_q]}, " if params[:observable_q].present?
      query += "threat_actor_q: #{params[:threat_actor_q]}, " if params[:threat_actor_q].present?
      query += "observable_type: #{params[:observable_type]}, " if params[:observable_type].present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      search = Indicator.search do 
        # https://github.com/sunspot/sunspot#disjunctions-and-conjunctions
        # Search through the text fields for title, reference, threat_actor, observable value, and observable_type if given
        all do 
          fulltext params[:title_q], :fields => [:title, :title_exact] if params[:title_q].present?
          fulltext params[:reference_q], :fields => :reference if params[:reference_q].present?
          fulltext params[:threat_actor_q], :fields => :threat_actor_title if params[:threat_actor_q].present?
          
          if params[:observable_q].present?
            params[:observable_q] = params[:observable_q]
            # full text search must happen on all observable values but not other text fields.
            fulltext params[:observable_q],
              :fields => [
                :addresses,
                :domains,
                :hostnames,
                :hostnames_naming_system,
                :dns_records_domain,
                :dns_records_address,
                :dns_query_question,
                :dns_query_domains,
                :dns_query_addresses,
                :email_messages_from,
                :email_messages_reply_to,
                :email_messages_sender,
                :email_messages_subject,
                :uris,
                :links,
                :file,
                :mutex,
                :http_session_user_agent,
                :http_session_domain_name,
                :http_session_referer,
                :registry_key,
                :registry_hive,
                :network_connection_dest_socket_address,
                :network_connection_dest_socket_hostname,
                :network_connection_dest_socket_port,
                :network_connection_source_socket_address,
                :network_connection_source_socket_hostname,
                :network_connection_source_socket_port,
                :network_connection_layer3_protocol,
                :network_connection_layer4_protocol,
                :network_connection_layer7_protocol,
                :port,
                :port_layer4_protocol,
                :hashes,
                :observable_value
              ]
          end
        end

        if params[:observable_type].present?
          with(:observable_type, params[:observable_type])
        end

        # add date range filter for updated_at time field
        if params[:ebt].present? && params[:iet].present?
          with(:updated_at, params[:ebt]..params[:iet])
        end

        # for asc desc sort
        if params[:column].present? && params[:direction].present?
          order_by(params[:column],params[:direction])
        end

        # If ais get only those.
        if params[:is_ais].present? && params[:is_ais] == true
          with(:is_ais, params[:is_ais]) 
        end

        # Search through indicator_type string field
        if params[:indicator_type].present?
          with(:indicator_type, params[:indicator_type]) 
        end
        
        # adjust the solr params for offset and limit for pagination
        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def package_search(q, params = {})

      StixPackage.search do
        if q.present?
          query = ""
          query += "q: #{q}, " if q.present?
    
          if query[query.length-2..query.length] == ", "
            query = query[0...query.length-2]
          end
    
          Logging::SearchLog.create(query: query, user: User.current_user) unless params[:mainsearch]

          fulltext q
        else
          all do 
            fulltext params[:title_q], :fields => [:title, :title_exact] if params[:title_q].present?
            fulltext params[:created_by_q], :fields => :username if params[:created_by_q].present?
            fulltext params[:short_desc_q], :fields => [:short_description, :short_description_exact] if params[:short_desc_q].present?
          end 
          q = ""
          q = q + "Title: " + params[:title_q] if params[:title_q].present?
          q = q + " Created by: " + params[:created_by_q] if params[:created_by_q].present?
          q = q + " Short descripton: " + params[:short_desc_q] if params[:short_desc_q].present?
          Logging::SearchLog.create(query: q,user: User.current_user) unless params[:mainsearch]
        end

        if params[:column].present? && params[:direction].present?
          order_by(params[:column],params[:direction])
        end

        if params[:created_ebt].present? && params[:created_iet].present?
          with(:created_at,params[:created_ebt]..params[:created_iet])
        end

        if params[:updated_ebt].present? && params[:updated_iet].present?
          with(:updated_at,params[:updated_ebt]..params[:updated_iet])
        end

        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def dns_record_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      DnsRecord.search do
        fulltext q
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:created_at,params[:ebt]..params[:iet])
        end
        with(:address_value_normalized, params[:address]) if params[:address]
        with(:domain_normalized, params[:name]) if params[:name]
        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def domain_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user) unless params[:mainsearch]

      Domain.search do
        fulltext q
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:created_at,params[:ebt]..params[:iet])
        end
        without(:combined_score,nil) if params[:weather_map_only] && params[:weather_map_only].to_bool
        with(:name_normalized, params[:name]) if params[:name]
        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def domain_type_ahead(type_ahead, params = {})
      if type_ahead.present? && type_ahead[type_ahead.length-1] != "*"
        type_ahead = type_ahead + "*"
      end

      Logging::SearchLog.create(query: type_ahead,user: User.current_user)

      Domain.search do
        fulltext type_ahead
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:created_at,params[:ebt]..params[:iet])
        end
        without(:combined_score,nil) if params[:weather_map_only] && params[:weather_map_only].to_bool
        with(:name_normalized, params[:name]) if params[:name]
        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]
        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end
    
    def hostname_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      Hostname.search do
        fulltext q
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:created_at,params[:ebt]..params[:iet])
        end
        with(:hostname_normalized, params[:hostname]) if params[:hostname]
        with(:naming_system, params[:naming_system]) if params[:naming_system]
        with(:is_domain_name, params[:is_domain_name]) if params[:is_domain_name]
        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def email_message_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      EmailMessage.search do
        fulltext q
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:created_at,params[:ebt]..params[:iet])
        end
        with(:from_normalized, params[:from]) if params[:from]
        with(:reply_to_normalized, params[:reply_to]) if params[:reply_to]
        with(:sender_normalized, params[:sender]) if params[:sender]
        with(:subject, params[:subject]) if params[:subject]
        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def cybox_file_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      CyboxFile.search do
        fulltext q
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:created_at,params[:ebt]..params[:iet])
        end
        with(:file_name, params[:name]) if params[:name]
        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
          sunspot_params[:qf] += ' file_name_exact'
        end
      end
    end

    def http_session_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      HttpSession.search do
        fulltext q
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:created_at,params[:ebt]..params[:iet])
        end
        with(:user_agent, params[:user_agent]) if params[:user_agent]
        with(:domain_name, params[:domain_name]) if params[:domain_name]
        with(:referer, params[:referer]) if params[:referer]
        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def address_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user) unless params[:mainsearch]

      network = nil
      broadcast = nil

      begin
        IPAddr.new(q.to_s)
        ip = IPAddress(q.to_s)
        if ip.class == IPAddress::IPv4
          network = ip.network.to_u32
          broadcast = ip.broadcast.to_u32
        end
      rescue ArgumentError, NoMethodError => e
        ip = nil
        network = nil
        broadcast = nil
      end

      Address.search do
        if ip.present? && network.present? && broadcast.present?   #Valid IPv4, Perform Integer based Range Search
          all_of do
            any_of do
              with(:ip_value_calculated_start).greater_than(network)
              with(:ip_value_calculated_start).equal_to(network)
            end
            any_of do
              with(:ip_value_calculated_end).less_than(broadcast)
              with(:ip_value_calculated_end).equal_to(broadcast)
            end
          end
        else #Invalid IPv4, perform Full Text search
          fulltext q
        end

        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:created_at,params[:ebt]..params[:iet])
        end
        without(:combined_score,nil) if params[:weather_map_only] && params[:weather_map_only].to_bool
        with(:address_value_normalized, params[:address]) if params[:address]

        any_of do
          params[:category].split(',').each do |cat|
            with(:category, cat)
          end
        end if params[:category]
        
        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]
        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def mutex_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      CyboxMutex.search do
        fulltext q
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:created_at,params[:ebt]..params[:iet])
        end
        with(:name_normalized, params[:name]) if params[:name]
        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def network_connection_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      NetworkConnection.search do
        fulltext q
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:created_at,params[:ebt]..params[:iet])
        end
        with(:dest_socket_address, params[:dest_socket_address]) if params[:dest_socket_address]
        with(:dest_socket_hostname, params[:dest_socket_hostname]) if params[:dest_socket_hostname]
        with(:dest_socket_is_spoofed, params[:dest_socket_is_spoofed]) if params[:dest_socket_is_spoofed]
        with(:dest_socket_port, params[:dest_socket_port]) if params[:dest_socket_port]
        with(:source_socket_address, params[:source_socket_address]) if params[:source_socket_address]
        with(:source_socket_hostname, params[:source_socket_hostname]) if params[:source_socket_hostname]
        with(:source_socket_is_spoofed, params[:source_socket_is_spoofed]) if params[:source_socket_is_spoofed]
        with(:source_socket_port, params[:source_socket_port]) if params[:source_socket_port]
        with(:layer3_protocol, params[:layer3_protocol]) if params[:layer3_protocol]
        with(:layer4_protocol, params[:layer4_protocol]) if params[:layer4_protocol]
        with(:layer7_protocol, params[:layer7_protocol]) if params[:layer7_protocol]
        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]
        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end
    
    #port
    def port_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      Port.search do
        fulltext q
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:created_at,params[:ebt]..params[:iet])
        end
        with(:port, params[:port]) if params[:port]
        with(:layer4_protocol, params[:layer4_protocol]) if params[:layer4_protocol]
        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def registry_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      Registry.search do
        fulltext q
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:created_at,params[:ebt]..params[:iet])
        end
        with(:hive, params[:hive]) if params[:hive]
        with(:key, params[:key]) if params[:key]
        with(:reg_name, params[:reg_name]) if params[:reg_name]
        with(:reg_value, params[:reg_value]) if params[:reg_value]
        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def uri_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      Uri.search do
        fulltext q
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:created_at,params[:ebt]..params[:iet])
        end
        with(:uri_normalized, params[:uri_in]) if params[:uri_in]
        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
          sunspot_params[:qf] += ' uri_uax'
        end
      end
    end

    def link_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      Link.search do
        fulltext q
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:created_at,params[:ebt]..params[:iet])
        end
        with(:label, params[:label]) if params[:label]
        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
          sunspot_params[:qf] += ' uri_uax' if sunspot_params[:qf].present?
        end
        data_accessor_for(Link).include = [:uri]
      end
    end

    def uploads_search(q, params = {})
      Logging::SearchLog.create(query: q,user: User.current_user)

      UploadedFile.search do
        fulltext q
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:created_at,params[:ebt]..params[:iet])
        end
        with(:user_guid, params[:user_guid]) unless params[:admin_search]
        with(:file_name, params[:file_name]) if params[:file_name]  
        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

		def exported_indicator_search(q,params = {})
			Logging::SearchLog.create(query: q,user: User.current_user)

			ExportedIndicator.search do
				fulltext q

        with(:system, params[:system])

				if params[:column] && params[:direction]
					order_by(params[:column],params[:direction])
				end
				if params[:ebt] && params[:iet]
					with(:exported_at,params[:ebt]..params[:iet])
				end
				if params[:indicator_type].present?
					with(:indicator_type, params[:indicator_type])
				end
				 
				if params[:observable_type]
					with(:remote_object_type, params[:observable_type])
				end

				adjust_solr_params do |sunspot_params|
					sunspot_params[:start] = params[:offset]
					sunspot_params[:rows] = params[:limit]
				end
			end

		end

    def threat_actor_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

	    ThreatActor.search do
		    fulltext q
		    if params[:column] && params[:direction]
			    order_by(params[:column],params[:direction])
		    end
		    if params[:ebt] && params[:iet]
			    with(:created_at,params[:ebt]..params[:iet])
		    end

		    adjust_solr_params do |sunspot_params|
			    sunspot_params[:start] = params[:offset]
			    sunspot_params[:rows] = params[:limit]
		    end
	    end
    end
    
    def course_of_action_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      CourseOfAction.search do
        fulltext q
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:updated_at,params[:ebt]..params[:iet])
        end

        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def exploit_target_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      ExploitTarget.search do
        fulltext q
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:updated_at,params[:ebt]..params[:iet])
        end

        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def vulnerability_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      Vulnerability.search do
        fulltext q
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:updated_at,params[:ebt]..params[:iet])
        end

        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def ttp_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      Ttp.search do
        fulltext q
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:updated_at,params[:ebt]..params[:iet])
        end

        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def attack_pattern_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      AttackPattern.search do
        fulltext q
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:updated_at,params[:ebt]..params[:iet])
        end

        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def socket_address_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      SocketAddress.search do
        fulltext q
        
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:updated_at,params[:ebt]..params[:iet])
        end

        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def dns_query_search(q, params = {})
      query = ""
      query += "q: #{q}, " if q.present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      network = nil
      broadcast = nil

      DnsQuery.search do
        fulltext q
        
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:updated_at,params[:ebt]..params[:iet])
        end

        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def question_search(q, params = {})
      Logging::SearchLog.create(query: q,user: User.current_user)

      network = nil
      broadcast = nil

      Question.search do
        fulltext q
        
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:updated_at,params[:ebt]..params[:iet])
        end

        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]

        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def resource_record_search(q, params = {})
      Logging::SearchLog.create(query: q,user: User.current_user)

      network = nil
      broadcast = nil

      ResourceRecord.search do
        fulltext q
        
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:updated_at,params[:ebt]..params[:iet])
        end

        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]
        
        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def layer_seven_connections_search(q, params = {})
      Logging::SearchLog.create(query: q,user: User.current_user)

      network = nil
      broadcast = nil

      LayerSevenConnection.search do
        fulltext q
        
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        if params[:ebt] && params[:iet]
          with(:updated_at,params[:ebt]..params[:iet])
        end

        with(:portion_marking).any_of(Classification.list_allowable(params[:classification_limit])) if params[:classification_limit]
        with(:portion_marking).any_of(Classification.list_allowable_greater(params[:classification_greater])) if params[:classification_greater]
        
        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def contributing_source_search(q, params = {})
      Logging::SearchLog.create(query: q,user: User.current_user)

      ContributingSource.search do
        fulltext q
        if params[:column] && params[:direction]
          order_by(params[:column],params[:direction])
        end
        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

    def ais_statistic_search(params = {})
      # Log query that needs to run against the search engine
      query = ""
      query += "sanitized_q: #{params[:sanitized_q]}, " if params[:sanitized_q].present?
      query += "original_q: #{params[:original_q]}, " if params[:original_q].present?
      query += "received_time: #{params[:received_time_ebt]}..#{params[:received_time_iet]}, " if params[:received_time_ebt].present? && params[:received_time_iet]
      query += "disseminated_time: #{params[:disseminated_time_ebt]}..#{params[:disseminated_time_iet]}, " if params[:disseminated_time_ebt].present? && params[:disseminated_time_iet]
      query += "disseminated_time_hr: #{params[:disseminated_time_hr_ebt]}..#{params[:disseminated_time_hr_iet]}, " if params[:disseminated_time_hr_ebt].present? && params[:disseminated_time_hr_iet]
      query += "indicator_amount_q: #{params[:indicator_amount_q]}, " if params[:indicator_amount_q].present?
      query += "flare_in_status_q: #{params[:flare_in_status_q]}, " if params[:flare_in_status_q].present?
      query += "ciap_status_q: #{params[:ciap_status_q]}, " if params[:ciap_status_q].present?
      query += "ecis_status_q: #{params[:ecis_status_q]}, " if params[:ecis_status_q].present?
      query += "flare_out_status_q: #{params[:flare_out_status_q]}, " if params[:flare_out_status_q].present?
      query += "feeds_q: #{params[:feeds_q]}, " if params[:feeds_q].present?
      query += "hr_count_q: #{params[:hr_count_q]}, " if params[:hr_count_q].present?
      query += "ecis_hr_status_q: #{params[:ecis_hr_status_q]}, " if params[:ecis_hr_status_q].present?
      query += "flare_out_hr_status_q: #{params[:flare_out_hr_status_q]}" if params[:flare_out_hr_status_q].present?

      if query[query.length-2..query.length] == ", "
        query = query[0...query.length-2]
      end

      Logging::SearchLog.create(query: query, user: User.current_user)

      search = AisStatistic.search do 
        # https://github.com/sunspot/sunspot#disjunctions-and-conjunctions
        all do 
          fulltext params[:sanitized_q], :fields => :stix_package_stix_id if params[:sanitized_q].present?
          fulltext params[:original_q], :fields => :stix_package_original_id if params[:original_q].present?
          fulltext params[:feeds_q], :fields => :feeds if params[:feeds_q].present?
          fulltext params[:hr_count_q], :fields => :human_review_status if params[:hr_count_q].present?

          with(:indicator_amount, params[:indicator_amount_q]) if params[:indicator_amount_q].present?

          with(:flare_in_status, params[:flare_in_status_q]) if !params[:flare_in_status_q].nil?
          with(:ciap_status, params[:ciap_status_q]) if !params[:ciap_status_q].nil?
          with(:ecis_status, params[:ecis_status_q]) if !params[:ecis_status_q].nil?
          with(:flare_out_status, params[:flare_out_status_q]) if !params[:flare_out_status_q].nil?
          with(:ecis_status_hr, params[:ecis_hr_status_q]) if !params[:ecis_hr_status_q].nil?
          with(:flare_out_status_hr, params[:flare_out_hr_status_q]) if !params[:flare_out_hr_status_q].nil?

          # add date range filter for received_time time field
          with(:received_time, (params[:received_time_ebt].to_date.beginning_of_day)..(params[:received_time_iet].to_date.end_of_day)) if params[:received_time_ebt].present? && params[:received_time_iet].present?
          # add date range filter for disseminated_time time field
          with(:dissemination_time, (params[:disseminated_time_ebt].to_date.beginning_of_day)..(params[:disseminated_time_iet].to_date.end_of_day)) if params[:disseminated_time_ebt].present? && params[:disseminated_time_iet].present?
          # add date range filter for disseminated_time_hr time field
          with(:dissemination_time_hr, (params[:disseminated_time_hr_ebt].to_date.beginning_of_day)..(params[:disseminated_time_hr_iet].to_date.end_of_day)) if params[:disseminated_time_hr_ebt].present? && params[:disseminated_time_hr_iet].present?
          
        end

        # for asc desc sort
        if params[:column].present? && params[:direction].present?
          order_by(params[:column],params[:direction])
        end

        # adjust the solr params for offset and limit for pagination
        adjust_solr_params do |sunspot_params|
          sunspot_params[:start] = params[:offset]
          sunspot_params[:rows] = params[:limit]
        end
      end
    end

  end
end
