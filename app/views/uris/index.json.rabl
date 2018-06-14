object false

child @metadata do
  attributes :total_count
end

child @uris, :root => "uris" do
  extends "uris/show", locals: {associations: locals[:associations]}
end
