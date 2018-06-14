object @parameter_observable => 'parameter_observable'

attributes :cybox_object_id,
           :stix_course_of_action_id,
           :remote_object_id,
           :remote_object_type,
           :guid,
           :portion_marking,
           :created_at,
           :updated_at

child :course_of_actions do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if locals[:associations][:course_of_actions]

child :address do
  extends "addresses/show", locals: {associations: locals[:associations]}
end

child :dns_record do
  extends "dns_records/show", locals: {associations: locals[:associations]}
end

child :domain do
  extends "domains/show", locals: {associations: locals[:associations]}
end

child :email_message do
  extends "email_messages/show", locals: {associations: locals[:associations]}
end

child :file => :file do
  extends "files/show", locals: {associations: locals[:associations]}
end

child :http_session do
  extends "http_sessions/show", locals: {associations: locals[:associations]}
end

child :hostname do
  extends "hostnames/show", locals: {associations: locals[:associations]}
end

child :link do
  extends "links/show", locals: {associations: locals[:associations]}
end

child :mutex => :mutex do
  extends "mutexes/show", locals: {associations: locals[:associations]}
end

child :network_connection => :network_connection do
  extends "network_connections/show", locals: {associations: locals[:associations]}
end

child :port => :port do
  extends "ports/show", locals: {associations: locals[:associations]}
end

child :registry=> :registry do
  extends "registries/show", locals: {associations: locals[:associations]}
end

child :socket_address => :socket_address do
  extends "socket_addresses/show", locals: {associations: locals[:associations]}
end

child :uri do
  extends "uris/show", locals: {associations: locals[:associations]}
end

child :audits => 'audits' do
  extends "groups/index", locals: {associations: locals[:associations]}
end if locals[:associations][:audits]
