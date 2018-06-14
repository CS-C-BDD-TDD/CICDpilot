object false

child @metadata do
  attributes :total_count
end

child @links, :root => "links" do
  extends "links/show", locals: {associations: locals[:associations]}
end
