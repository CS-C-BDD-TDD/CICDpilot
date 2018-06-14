object false

node :metadata do
  {
    total_indicators_count: @total_indicators_count,
    total_weather_map_addresses_count: @total_weather_map_addresses_count,
    total_weather_map_domains_count: @total_weather_map_domains_count
  }
end

child @indicators, :root => "indicators" do
  extends("indicators/show", locals: {associations: locals[:associations]})
end

child @weather_map_addresses, :root => "weather_map_addresses" do
  extends("addresses/show", locals: {associations: locals[:associations]})
end

child @weather_map_domains, :root => "weather_map_domains" do
  extends("domains/show", locals: {associations: locals[:associations]})
end
