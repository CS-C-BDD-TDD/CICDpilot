if @hostnames
    object false

    child @metadata do
        attributes :total_count
    end

    child @hostnames, :root => "hostnames" do
        extends "hostnames/show", locals: {associations: locals[:associations]}
    end
 else
    collection @hostnames

    extends("hostnames/show", locals: {associations: locals[:associations]})
end
