if @vulnerabilities
  object false

  child @metadata do
    attributes :total_count
  end

  child @vulnerabilities, :root => "vulnerabilities" do
  	extends "vulnerabilities/show", locals: {associations: locals[:associations]}
  end

else
  collection @vulnerabilities

  extends("vulnerabilities/show", locals: {associations: locals[:associations]})
end
