if @socket_addresses
  object false
  child @metadata do
    attributes :total_count
  end
  child @socket_addresses, :root => "socket_addresses" do
    extends "socket_addresses/show", locals: {associations: locals[:associations]}
  end
else
  collection @socket_addresses
  extends("socket_addresses/show", locals: {associations: locals[:associations]})
end
