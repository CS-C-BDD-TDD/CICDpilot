object @network_connection

attributes :cybox_object_id,
           :dest_socket_address,
           :dest_socket_hostname,
           :dest_socket_is_spoofed,
           :dest_socket_port,
           :source_socket_address,
           :source_socket_hostname,
           :source_socket_is_spoofed,
           :source_socket_port,
           :layer3_protocol,
           :layer4_protocol,
           :layer7_protocol,
           :created_at,
           :updated_at,
           :guid,
           :portion_marking,
           :read_only,
           :dest_socket_address_c,
           :dest_socket_port_c,
           :source_socket_address_c,
           :source_socket_port_c,
           :layer3_protocol_c,
           :layer4_protocol_c,
           :layer7_protocol_c,
           :dest_socket_hostname_c,
           :source_socket_hostname_c,
           :is_ciscp,
           :is_mifr,
		   :feeds


child :indicators => 'indicators' do
  extends "indicators/index.json.rabl", locals: {associations: locals[:associations].merge({confidences: 'embedded',observable: 'embedded'})}
end if (locals['network_connection'] || locals[:associations][:indicators]) && locals[:associations][:indicators] != 'none'

child :course_of_actions => 'course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['network_connection'] || locals[:associations][:course_of_actions]) && locals[:associations][:course_of_actions] != 'none'

child :ind_course_of_actions => 'ind_course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['network_connection'] || locals[:associations][:ind_course_of_actions]) && locals[:associations][:ind_course_of_actions] != 'none'

node :stix_markings do |network_connection|
  stix_markings = network_connection.stix_markings.to_a
  partial 'stix_markings/index.json.rabl', object: stix_markings
end if (locals['network_connection'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['network_connection'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'
