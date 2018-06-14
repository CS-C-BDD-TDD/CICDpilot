object false

child @metadata do
  attributes :total_count
end

child @emails, :root => "email_messages" do
  extends "email_messages/show", locals: {associations: locals[:associations]}
end
