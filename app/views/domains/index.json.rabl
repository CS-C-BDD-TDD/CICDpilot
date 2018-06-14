object false

child @metadata do
  attributes :total_count
end

child @domains, :root => "domains" do
  extends "domains/show", locals: {associations: locals[:associations]}
end
