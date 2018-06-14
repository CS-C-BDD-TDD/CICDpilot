object false

child @metadata do
  attributes :total_count
end

child @registries, :root => "registries" do
  extends "registries/show", locals: {associations: locals[:associations]}
end
