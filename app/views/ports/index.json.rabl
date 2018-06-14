if @ports
    object false

    child @metadata do
        attributes :total_count
    end

    child @ports, :root => "ports" do
        extends "ports/show", locals: {associations: locals[:associations]}
    end
 else
    collection @ports

    extends("ports/show", locals: {associations: locals[:associations]})
end
