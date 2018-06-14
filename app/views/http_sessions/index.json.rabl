object false

child @metadata do
  attributes :total_count
end

child @http_sessions, :root => "http_sessions" do
  extends "http_sessions/show", locals: {associations: locals[:associations]}
end
