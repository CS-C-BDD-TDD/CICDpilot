if @course_of_actions
  object false

  child @metadata do
    attributes :total_count
  end

  child @course_of_actions, :root => "course_of_actions" do
  	extends "course_of_actions/show", locals: {associations: locals[:associations]}
  end

else
  collection @course_of_actions

  extends("course_of_actions/show", locals: {associations: locals[:associations]})
end
