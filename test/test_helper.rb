ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  fixtures :all

  def setup_api_user
    o = Organization.create!(short_name:'US-CERT',long_name:'USA-CERT')
    user = User.new
    user.username = 'svcadmin'
    user.password = 'P@ssw0rd!'
    user.first_name = 'Cyber'
    user.last_name = 'Admin'
    user.email = 'svcadmin@test.com'
    user.machine = true
    user.organization = o
    User.current_user = user
    user.save
    user.generate_api_key
    #Line causes "ActiveRecordError : cannot update a new record", disable for now
    #user.change_api_key_secret('secret')
    api_key_hash = Digest::SHA2.hexdigest("#{user.api_key}@secret")
    @headers = {'HTTP_API_KEY'=>user.api_key,'HTTP_API_KEY_HASH'=>api_key_hash,'ACCEPT'=>'application/json'}
    @user = user
  end

  def default_permissions(user=nil)
    user ||= @user
    permissions = [{
                     name: 'create_indicator_observable',
                     description: 'Create Indicators and Observables'
                   },
                   {
                     name: 'modify_all_items',
                     description: 'Modify Items'
                   },
                   {
                     name: 'create_package_report',
                     description: 'Package Report'
                   },
                   {
                     name: 'view_pii_fields',
                     description: 'View PII Fields'
                   },
                   {
                     name: 'tag_item_with_user_tag',
                     description: 'Tag item w/ user tag'
                   },
                   {
                     name: 'tag_item_with_system_tag',
                     description: 'Tag item w/ system tag'
                   },
                   {
                     name: 'view_user_organization',
                     description: 'View Users, Organizations and Groups'
                   },
                   {
                     name: 'create_modify_user_organization',
                     description: 'Create or Modify Users, Organizations and Groups'
                   }]
    permissions.map! {|attributes| p = Permission.new(attributes)}
    permissions.map &:save
    group = Group.new({name:'API',description:'API Group'})
    group.permissions = Permission.all
    group.save
    user.groups = [group]
    user.save
  end

  def expectation(left,operator,right)
    result = left.send(operator,right)
    message = "Expected, #{left}, to, #{operator}, #{right}."
    return [result,message]
  end

  def assert_json_indicator(ind_resp, indicator)
    assert ind_resp.has_key?('is_reference')
    assert ind_resp.has_key?('parent_id')
    assert ind_resp.has_key?('resp_entity_stix_ident_id')
    assert ind_resp.has_key?('stix_id')
    assert ind_resp.has_key?('stix_timestamp')
    assert ind_resp.has_key?('updated_at')
    assert ind_resp.has_key?('guid')
    assert ind_resp.has_key?('title'),'Indicator does not have a title'
    assert ind_resp.has_key?('description')
    assert ind_resp.has_key?('composite_operator')
    assert ind_resp.has_key?('created_at')
    assert ind_resp.has_key?('indicator_type')
    assert ind_resp.has_key?('indicator_type_vocab_name')
    assert ind_resp.has_key?('indicator_type_vocab_ref')
    assert ind_resp.has_key?('is_composite')
    assert ind_resp.has_key?('is_negated')
    assert *expectation(ind_resp['title'],:==,indicator.title)
    assert *expectation(ind_resp['description'],:==,indicator.description)
    assert *expectation(ind_resp['composite_operator'],:==,indicator.composite_operator)
    assert *expectation(ind_resp['created_at'].to_date,:==,indicator.created_at.to_date)
    assert *expectation(ind_resp['indicator_type'],:==,indicator.indicator_type.to_s)
    assert *expectation(ind_resp['indicator_type_vocab_name'],:==,indicator.indicator_type_vocab_name)
    assert *expectation(ind_resp['indicator_type_vocab_ref'],:==,indicator.indicator_type_vocab_ref)
    assert *expectation(ind_resp['is_composite'],:==,indicator.is_composite)
    assert *expectation(ind_resp['is_negated'],:==,indicator.is_negated)
    assert *expectation(ind_resp['is_reference'],:==,indicator.is_reference)
    assert *expectation(ind_resp['parent_id'],:==,indicator.parent_id)
    assert *expectation(ind_resp['resp_entity_stix_ident_id'],:==,indicator.resp_entity_stix_ident_id)
    assert *expectation(ind_resp['stix_id'],:==,indicator.stix_id)
    assert *expectation(ind_resp['stix_timestamp'],:==,indicator.stix_timestamp)
    assert *expectation(ind_resp['updated_at'].to_date,:==,indicator.updated_at.to_date)
    assert *expectation(ind_resp['guid'],:==,indicator.guid)
  end

  def assert_json_observable(obs_resp, observable)
    assert obs_resp.has_key?('cybox_object_id') && obs_resp['cybox_object_id'] == observable.cybox_object_id
    assert obs_resp.has_key?('stix_indicator_id') && obs_resp['stix_indicator_id'] == observable.stix_indicator_id
    assert obs_resp.has_key?('remote_object_id') && obs_resp['remote_object_id'] == observable.remote_object_id
    assert obs_resp.has_key?('remote_object_type') && obs_resp['remote_object_type'] == observable.remote_object_type
    assert obs_resp.has_key?('guid') && obs_resp['guid'] == observable.guid
  end

  def assert_json_domain(dom_resp,domain)
    assert dom_resp.has_key?('name') && dom_resp['name'] == domain.name_normalized
    assert dom_resp.has_key?('cybox_object_id') && dom_resp['cybox_object_id'] == domain.cybox_object_id
    assert dom_resp.has_key?('name_input') && dom_resp['name_input'] == domain.name_raw
    assert dom_resp.has_key?('name_condition') && dom_resp['name_condition'] == domain.name_condition
    assert dom_resp.has_key?('root_domain') && dom_resp['root_domain'] == domain.root_domain
    assert dom_resp.has_key?('created_at') && dom_resp['created_at'].to_date == domain.created_at.to_date
    assert dom_resp.has_key?('updated_at') && dom_resp['updated_at'].to_date == domain.updated_at.to_date
    assert dom_resp.has_key?('guid') && dom_resp['guid'] == domain.guid
  end

  def assert_json_address(addr_resp,address)
    assert addr_resp.has_key?('cybox_object_id') && addr_resp['cybox_object_id'] == address.cybox_object_id
    assert addr_resp.has_key?('created_at') && addr_resp['created_at'].to_date == address.created_at.to_date
    assert addr_resp.has_key?('updated_at') && addr_resp['updated_at'].to_date == address.updated_at.to_date
    assert addr_resp.has_key?('address') && addr_resp['address'] == address.address_value_normalized
    assert addr_resp.has_key?('address_input') && addr_resp['address_input'] == address.address_value_raw
    assert addr_resp.has_key?('category') && addr_resp['category'] == address.category
    assert addr_resp.has_key?('ip_value_calculated_start') && addr_resp['ip_value_calculated_start'] == address.ip_value_calculated_start
    assert addr_resp.has_key?('ip_value_calculated_end') && addr_resp['ip_value_calculated_end'] == address.ip_value_calculated_end
    assert addr_resp.has_key?('guid') && addr_resp['guid'] == address.guid
  end

  def assert_json_uri(uri_resp,uri)
    assert uri_resp.has_key?('cybox_object_id') && uri_resp['cybox_object_id'] == uri.cybox_object_id
    assert uri_resp.has_key?('uri') && uri_resp['uri'] == uri.uri_normalized
    assert uri_resp.has_key?('uri') && uri_resp['uri'] == uri.uri_raw
    assert uri_resp.has_key?('uri_type') && uri_resp['uri_type'] == uri.uri_type
    assert uri_resp.has_key?('updated_at') && uri_resp['updated_at'].to_date == uri.updated_at.to_date
    assert uri_resp.has_key?('created_at') && uri_resp['created_at'].to_date == uri.created_at.to_date
    assert uri_resp.has_key?('guid') && uri_resp['guid'] == uri.guid
  end

  def assert_json_http_session(http_session_resp,http_session)
    assert http_session_resp.has_key?('cybox_object_id') && http_session_resp['cybox_object_id'] == http_session.cybox_object_id
    assert http_session_resp.has_key?('user_agent') && http_session_resp['user_agent'] == http_session.user_agent
    assert http_session_resp.has_key?('domain_name') && http_session_resp['domain_name'] == http_session.domain_name
    assert http_session_resp.has_key?('port') && http_session_resp['port'] == http_session.port
    assert http_session_resp.has_key?('referer') && http_session_resp['referer'] == http_session.referer
    assert http_session_resp.has_key?('pragma') && http_session_resp['pragma'] == http_session.pragma
    assert http_session_resp.has_key?('updated_at') && http_session_resp['updated_at'].to_date == http_session.updated_at.to_date
    assert http_session_resp.has_key?('created_at') && http_session_resp['created_at'].to_date == http_session.created_at.to_date
    assert http_session_resp.has_key?('guid') && http_session_resp['guid'] == http_session.guid
  end

  def assert_json_mutex(mutex_resp,mutex)
    assert mutex_resp.has_key?('cybox_object_id') && mutex_resp['cybox_object_id'] == mutex.cybox_object_id
    assert mutex_resp.has_key?('name') && mutex_resp['name'] == mutex.name
    assert mutex_resp.has_key?('updated_at') && mutex_resp['updated_at'].to_date == mutex.updated_at.to_date
    assert mutex_resp.has_key?('created_at') && mutex_resp['created_at'].to_date == mutex.created_at.to_date
    assert mutex_resp.has_key?('guid') && mutex_resp['guid'] == mutex.guid
  end

  def assert_json_file(file_resp,file)
    assert file_resp.has_key?('cybox_object_id') && file_resp['cybox_object_id'] == file.cybox_object_id
    assert file_resp.has_key?('file_extension') && file_resp['file_extension'] == file.file_extension
    assert file_resp.has_key?('file_name') && file_resp['file_name'] == file.file_name
    assert file_resp.has_key?('file_name_condition') && file_resp['file_name_condition'] == file.file_name_condition
    assert file_resp.has_key?('file_path') && file_resp['file_path'] == file.file_path
    assert file_resp.has_key?('file_path_condition') && file_resp['file_path_condition'] == file.file_path_condition
    assert file_resp.has_key?('size_in_bytes') && file_resp['size_in_bytes'] == file.size_in_bytes
    assert file_resp.has_key?('size_in_bytes_condition') && file_resp['size_in_bytes_condition'] == file.size_in_bytes_condition
    assert file_resp.has_key?('created_at') && file_resp['created_at'].to_date == file.created_at.to_date
    assert file_resp.has_key?('updated_at') && file_resp['updated_at'].to_date == file.updated_at.to_date
    assert file_resp.has_key?('md5') && file.file_hashes[0].hash_type == 'MD5' && file_resp['md5'] == file.file_hashes[0].simple_hash_value
    assert file_resp.has_key?('sha1') && file.file_hashes[1].hash_type == 'SHA1' && file_resp['sha1'] == file.file_hashes[1].simple_hash_value
    assert file_resp.has_key?('sha256') && file.file_hashes[2].hash_type == 'SHA256' && file_resp['sha256'] == file.file_hashes[2].simple_hash_value
    assert file_resp.has_key?('ssdeep') && file.file_hashes[3].hash_type == 'SSDEEP' && file_resp['ssdeep'] == file.file_hashes[3].fuzzy_hash_value
    assert file_resp.has_key?('guid') && file_resp['guid'] == file.guid
  end

  def assert_json_dns_record(dns_resp,dns)
    assert dns_resp.has_key?('cybox_object_id') && dns_resp['cybox_object_id'] == dns.cybox_object_id
    assert dns_resp.has_key?('address_class') && dns_resp['address_class'] == dns.address_class
    assert dns_resp.has_key?('address') && dns_resp['address'] == dns.address_value_normalized
    assert dns_resp.has_key?('address_input') && dns_resp['address_input'] == dns.address_value_raw
    assert dns_resp.has_key?('domain') && dns_resp['domain'] == dns.domain_normalized
    assert dns_resp.has_key?('domain_input') && dns_resp['domain_input'] == dns.domain_raw
    assert dns_resp.has_key?('entry_type') && dns_resp['entry_type'] == dns.entry_type
    if (dns_resp.has_key?('queried_date') && !dns_resp['queried_date'].nil?)
      assert dns_resp['queried_date'].to_date == dns.queried_date.to_date
    end
    assert dns_resp.has_key?('created_at') && dns_resp['created_at'].to_date == dns.created_at.to_date
    assert dns_resp.has_key?('updated_at') && dns_resp['updated_at'].to_date == dns.updated_at.to_date
    assert dns_resp.has_key?('guid') && dns_resp['guid'] == dns.guid
  end

  def assert_json_email_message(email_resp,email)
    assert email_resp.has_key?('cybox_object_id') && email_resp['cybox_object_id'] == email.cybox_object_id
    assert email_resp.has_key?('created_at') && email_resp['created_at'].to_date == email.created_at.to_date
    assert email_resp.has_key?('updated_at') && email_resp['updated_at'].to_date == email.updated_at.to_date
    if (email_resp.has_key?('email_date') && !email_resp['email_date'].nil?)
      assert email_resp.has_key?('email_date') && email_resp['email_date'].to_date == email.email_date.to_date
    end
    assert email_resp.has_key?('from_normalized') && email_resp['from_normalized'] == email.from_normalized
    assert email_resp.has_key?('from_is_spoofed') && email_resp['from_is_spoofed'] == email.from_is_spoofed
    assert email_resp.has_key?('message_id') && email_resp['message_id'] == email.message_id
    assert email_resp.has_key?('raw_body') && email_resp['raw_body'] == email.raw_body
    assert email_resp.has_key?('raw_header') && email_resp['raw_header'] == email.raw_header
    assert email_resp.has_key?('reply_to_normalized') && email_resp['reply_to_normalized'] == email.reply_to_normalized
    assert email_resp.has_key?('sender_normalized') && email_resp['sender_normalized'] == email.sender_normalized
    assert email_resp.has_key?('sender_is_spoofed') && email_resp['sender_is_spoofed'] == email.sender_is_spoofed
    assert email_resp.has_key?('subject') && email_resp['subject'] == email.subject
    assert email_resp.has_key?('x_mailer') && email_resp['x_mailer'] == email.x_mailer
    assert email_resp.has_key?('x_originating_ip') && email_resp['x_originating_ip'] == email.x_originating_ip
    assert email_resp.has_key?('guid') && email_resp['guid'] == email.guid
  end

  def assert_json_registry(registry_resp,registry)
    assert registry_resp.has_key?('cybox_object_id') && registry_resp['cybox_object_id'] == registry.cybox_object_id
    assert registry_resp.has_key?('hive') && registry_resp['hive'] == registry.hive
    assert registry_resp.has_key?('key') && registry_resp['key'] == registry.key
    assert registry_resp.has_key?('created_at') && registry_resp['created_at'].to_date == registry.created_at.to_date
    assert registry_resp.has_key?('updated_at') && registry_resp['updated_at'].to_date == registry.updated_at.to_date
    assert registry_resp.has_key?('reg_name') && registry_resp['reg_name'] == registry.registry_values[0].reg_name
    assert registry_resp.has_key?('reg_value') && registry_resp['reg_value'] == registry.registry_values[0].reg_value
    assert registry_resp.has_key?('guid') && registry_resp['guid'] == registry.guid
  end

  def assert_json_network_connection(network_connection_resp,network_connection)
    assert network_connection_resp.has_key?('cybox_object_id') && network_connection_resp['cybox_object_id'] == network_connection.cybox_object_id
    assert network_connection_resp.has_key?('source_socket_address') && network_connection_resp['source_socket_address'] == network_connection.source_socket_address
    assert network_connection_resp.has_key?('source_socket_is_spoofed') && network_connection_resp['source_socket_is_spoofed'] == network_connection.source_socket_is_spoofed
    assert network_connection_resp.has_key?('source_socket_port') && network_connection_resp['source_socket_port'] == network_connection.source_socket_port
    assert network_connection_resp.has_key?('dest_socket_address') && network_connection_resp['dest_socket_address'] == network_connection.dest_socket_address
    assert network_connection_resp.has_key?('dest_socket_is_spoofed') && network_connection_resp['dest_socket_is_spoofed'] == network_connection.dest_socket_is_spoofed
    assert network_connection_resp.has_key?('dest_socket_port') && network_connection_resp['dest_socket_port'] == network_connection.dest_socket_port
    assert network_connection_resp.has_key?('layer4_protocol') && network_connection_resp['layer4_protocol'] == network_connection.layer4_protocol
    assert network_connection_resp.has_key?('created_at') && network_connection_resp['created_at'].to_date == network_connection.created_at.to_date
    assert network_connection_resp.has_key?('updated_at') && network_connection_resp['updated_at'].to_date == network_connection.updated_at.to_date
    assert network_connection_resp.has_key?('guid') && network_connection_resp['guid'] == network_connection.guid
  end

  def assert_json_package(pack_resp,package)
    assert pack_resp.has_key?('stix_id') && pack_resp['stix_id'] == package.stix_id
    assert pack_resp.has_key?('created_at') && pack_resp['created_at'].to_date == package.created_at.to_date
    assert pack_resp.has_key?('updated_at') && pack_resp['updated_at'].to_date == package.updated_at.to_date
    if (pack_resp.has_key?('stix_timestamp') && !pack_resp['stix_timestamp'].nil?)
      assert pack_resp.has_key?('stix_timestamp') && pack_resp['stix_timestamp'].to_date == package.stix_timestamp.to_date
    end
    assert pack_resp.has_key?('title') && pack_resp['title'] == package.title
    assert pack_resp.has_key?('description') && pack_resp['description'] == package.description
    assert pack_resp.has_key?('short_description') && pack_resp['short_description'] == package.short_description
    assert pack_resp.has_key?('info_src_produced_time') && pack_resp['info_src_produced_time'] == package.info_src_produced_time
    assert pack_resp.has_key?('is_reference') && pack_resp['is_reference'] == package.is_reference
    assert pack_resp.has_key?('package_intent') && pack_resp['package_intent'] == package.package_intent
    assert pack_resp.has_key?('username') && pack_resp['username'] == package.username
    assert pack_resp.has_key?('stix_id') && pack_resp['stix_id'] == package.stix_id
    assert pack_resp.has_key?('guid') && pack_resp['guid'] == package.guid
  end

  def assert_json_user(user_resp, user)
    assert user_resp.has_key?('username') && user_resp['username'] == user.username
    assert user_resp.has_key?('first_name') && user_resp['first_name'] == user.first_name
    assert user_resp.has_key?('last_name') && user_resp['last_name'] == user.last_name
    assert user_resp.has_key?('email') && user_resp['email'] == user.email
    assert user_resp.has_key?('phone') && user_resp['phone'] == user.phone
    assert user_resp.has_key?('api_key') && user_resp['api_key'] == user.api_key
    assert user_resp.has_key?('guid') && user_resp['guid'] == user.guid
  end

  def assert_json_group(group_resp,group)
    assert group_resp.has_key?('name')
    assert group_resp.has_key?('description')
    assert group_resp.has_key?('guid')
    # For whatever reason this syntax was not working
    #assert *expectation(group_resp['name'],:==,group.name)
    #assert *expectation(group_resp['description'],:==,group.description)
    #assert *expectation(group_resp['guid'],:==,group.guid)
    assert group_resp.has_key?('name') && group_resp['name'] == group.name
    assert group_resp.has_key?('description') && group_resp['description'] == group.description
    assert group_resp.has_key?('guid') && group_resp['guid'] == group.guid
  end

  def assert_json_permission(perm_resp,permission)
    assert perm_resp.has_key?('name') && perm_resp['name'] == permission.name
    assert perm_resp.has_key?('description') && perm_resp['description'] == permission.description
    assert perm_resp.has_key?('display_name') && perm_resp['display_name'] == permission.display_name
    assert perm_resp.has_key?('guid') && perm_resp['guid'] == permission.guid
  end

  def assert_json_audit(audit_resp, audit)
    assert audit_resp.has_key?('message') && audit_resp['message'] == audit.message
    assert audit_resp.has_key?('details') && audit_resp['details'] == audit.details
    assert audit_resp.has_key?('audit_type') && audit_resp['audit_type'] == audit.audit_type
    assert audit_resp.has_key?('justification') && (audit_resp['justification'] == audit.justification || (audit_resp['justification'].blank? && audit.justification.blank?))
    assert audit_resp.has_key?('event_time') && audit_resp['event_time'].to_date == audit.event_time.to_date
    assert audit_resp.has_key?('system_guid') && audit_resp['system_guid'] == audit.system_guid
  end
end
