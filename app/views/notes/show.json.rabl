object @note

attributes :guid,
           :note,
           :justification,
           :created_at

child :user do
  extends "users/show", locals: {associations: locals[:associations]}
end
