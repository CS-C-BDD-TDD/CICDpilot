if @addresses
  object false
  child @metadata do
    attributes :total_count
  end
  child @addresses, :root => "addresses" do
    extends "addresses/show", locals: {associations: locals[:associations]}
  end
else
  collection @addresses
  extends("addresses/show", locals: {associations: locals[:associations]})
end
