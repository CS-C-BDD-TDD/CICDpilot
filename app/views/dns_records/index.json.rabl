object false

child @metadata do
  attributes :total_count
end

child @dns_records, :root => "dns_records" do
  extends "dns_records/show", locals: {associations: locals[:associations]}
end
