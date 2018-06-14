object @observable => 'observable'

attributes :cybox_object_id,
           :stix_indicator_id,
           :remote_object_id,
           :remote_object_type,
           :guid,
           :portion_marking,
           :created_at,
           :updated_at

child :indicators do
  extends "indicators/index.json.rabl", locals: {associations: locals[:associations]}
end if locals[:associations][:indicators]

node :dns_query do |observable|
  observable.dns_query.as_json
end

node :dns_record do |observable|
  observable.dns_record.as_json
end

child :domain do
  extends "domains/show", locals: {associations: locals[:associations]}
end

child :hostname do
  extends "hostnames/show", locals: {associations: locals[:associations]}
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

child :address do
  extends "addresses/show", locals: {associations: locals[:associations]}
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

node :uri do |observable|
  observable.uri.as_json
end

child :audits => 'audits' do
  extends "groups/index", locals: {associations: locals[:associations]}
end if locals[:associations][:audits]
