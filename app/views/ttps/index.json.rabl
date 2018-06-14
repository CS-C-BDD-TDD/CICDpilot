if @ttps
  object false

  child @metadata do
    attributes :total_count
  end

  child @ttps, :root => "ttps" do
  	extends "ttps/show", locals: {associations: locals[:associations]}
  end

else
  collection @ttps

  extends("ttps/show", locals: {associations: locals[:associations]})
end
