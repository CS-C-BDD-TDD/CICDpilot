module ObservableHelper
  def collect_embedded_objects(obs)
    new_obs = obs.dup
    obs.each do |observable|

      if observable.email_message.present? 
        new_obs = collect_for_email_message(observable.email_message, new_obs)
      elsif observable.socket_address.present?
        new_obs = collect_for_socket_address(observable.socket_address, new_obs)
      elsif observable.dns_query.present?
        new_obs = collect_for_dns_query(observable.dns_query, new_obs)
      elsif observable.dns_record.present?
        new_obs = collect_for_dns_record(observable.dns_record, new_obs)
      elsif observable.network_connection.present?
        new_obs = collect_for_network_connection(observable.network_connection, new_obs)
      end # End If 
    end # End do

    new_obs.compact.uniq {|o| o.cybox_object_id && o.remote_object_id }
  end

  def collect_for_email_message(email_message, new_obs)
    email_message.links.each do |l|
      create_fake_observable(l) if l.observables.blank?
      new_obs << l.observables[0]
    end

    email_message.uris.each do |u|
      create_fake_observable(u) if u.observables.blank?
      new_obs << u.observables[0]
    end

    email_message.cybox_files.each do |f|
      create_fake_observable(f) if f.observables.blank?
      new_obs << f.observables[0]
    end

    address_fields = [
      :sender_address,
      :reply_to_address,
      :from_address,
      :x_ip_address
    ]

    address_fields.each do |af|
      add = email_message.send(af)
      if add.present?
        create_fake_observable(add) if add.observables.blank?
        new_obs << add.observables[0]
      end
    end

    new_obs
  end

  def collect_for_socket_address(socket_address, new_obs)
    socket_address_fields = [
      :addresses,
      :hostnames,
      :ports
    ]

    socket_address_fields.each do |field|
      objs = socket_address.send(field)
      objs.each do |obj|
        create_fake_observable(obj) if obj.observables.blank?
        new_obs << obj.observables[0]
      end
    end

    new_obs
  end

  def collect_for_dns_query(dns_query, new_obs)
    # need to search all the questions and resource records to find uri's and dns_records. then we need to make sure they have observables
    dns_query.questions.each do |x|
      x.uris.each do |obj|
        create_fake_observable(obj) if obj.observables.blank?
        new_obs << obj.observables[0]
      end
    end

    dns_query.resource_records.each do |x|
      x.dns_records.each do |obj|
        create_fake_observable(obj) if obj.observables.blank?
        new_obs << obj.observables[0]
        collect_for_dns_record(obj, new_obs)
      end
    end

    new_obs
  end

  def collect_for_dns_record(dns_record, new_obs)
    if dns_record.dns_address.present?
      obj = dns_record.dns_address
      create_fake_observable(obj) if obj.observables.blank?
      new_obs << obj.observables[0]
    end

    # We need to be able to accept in a domain for the domain name but then out put it as a uri?
    if dns_record.dns_domain.present?
      obj = dns_record.dns_domain
      create_fake_observable(obj) if obj.observables.blank?
      new_obs << obj.observables[0]
    end

    new_obs
  end

  def collect_for_network_connection(network_connection, new_obs)
    if network_connection.source_socket_address_obj.present?
      obj = network_connection.source_socket_address_obj
      create_fake_observable(obj) if obj.observables.blank?
      new_obs << obj.observables[0]
      collect_for_socket_address(network_connection.source_socket_address_obj, new_obs)
    end

    if network_connection.dest_socket_address_obj.present?
      obj = network_connection.dest_socket_address_obj
      create_fake_observable(obj) if obj.observables.blank?
      new_obs << obj.observables[0]
      collect_for_socket_address(network_connection.dest_socket_address_obj, new_obs)
    end

    if network_connection.layer_seven_connections.present?
      layer7 = network_connection.layer_seven_connections.first
      if layer7.http_session.present?
        obj = layer7.http_session
        create_fake_observable(obj) if obj.observables.blank?
        new_obs << obj.observables[0]
      end

      if layer7.dns_queries.present?
        layer7.dns_queries.each do |x|
          obj = x
          create_fake_observable(obj) if obj.observables.blank?
          new_obs << obj.observables[0]
          collect_for_dns_query(x, new_obs)
        end
      end
    end

    new_obs
  end

  # so that we can do object references if the object does not have an observable create a fake one.
  def create_fake_observable(obj)
    return if !obj.respond_to?(:observables) || obj.observables.present?

    Observable.create!(:remote_object_id => obj.cybox_object_id, :remote_object_type=> obj.class)
    obj.reload
  end
end
