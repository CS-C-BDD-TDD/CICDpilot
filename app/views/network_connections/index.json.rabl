object false

child @metadata do
  attributes :total_count
end

child @network_connections, :root => "network_connections" do
  extends "network_connections/show", locals: {associations: locals[:associations]}
end
