if @indicators
  object false

  child @metadata do
    attributes :total_count
  end

  child @indicators, :root => "indicators" do
    extends("indicators/show", locals: {associations: locals[:associations]})
  end

else
  collection @indicators

  extends("indicators/show", locals: {associations: locals[:associations]})
end
