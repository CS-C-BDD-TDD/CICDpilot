object false

child @metadata do
  attributes :total_count
end

child @mutexes, :root => "mutexes" do
  extends "mutexes/show", locals: {associations: locals[:associations]}
end
