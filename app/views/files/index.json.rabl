object false

child @metadata do
  attributes :total_count
end

child @files, :root => "files" do
  extends "files/show", locals: {associations: locals[:associations]}
end
