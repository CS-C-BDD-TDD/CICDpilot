if @attack_patterns
  object false

  child @metadata do
    attributes :total_count
  end

  child @attack_patterns, :root => "attack_patterns" do
  	extends "attack_patterns/show", locals: {associations: locals[:associations]}
  end

else
  collection @attack_patterns

  extends("attack_patterns/show", locals: {associations: locals[:associations]})
end
