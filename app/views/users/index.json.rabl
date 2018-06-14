if @users
  object false

  child @metadata do
    attributes :total_count
  end

  child @users, :root => "users" do
    extends("users/show", locals: {associations: locals[:associations]})
  end

else
	collection @users

	extends "users/show", locals: {associations: locals[:associations]}
end
