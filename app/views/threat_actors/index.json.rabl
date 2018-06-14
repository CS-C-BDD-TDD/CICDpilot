if @threat_actors
  object false

  child @metadata do
    attributes :total_count
  end

  child @threat_actors, :root => "threat_actors" do
  	extends "threat_actors/show", locals: {associations: locals[:associations]}
  end

else
  collection @threat_actors

  extends("threat_actors/show", locals: {associations: locals[:associations]})
end
