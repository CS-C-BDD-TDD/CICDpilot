require 'erb'

namespace :lux do
  task :reindex => :environment do |t,args|
    template_path = Rails.root.join('app','views','indicators','_lux.xml.erb')
    renderer = ERB.new File.read(template_path)
    uri = URI.parse("http://localhost:8983/lux/collection1/update")
    http = Net::HTTP.new(uri.host,uri.port)
    request = Net::HTTP::Post.new(uri.path,{'Content-Type' => 'text/xml'})

    indicators = Indicator.all
    indicators.each do |indicator|
      @indicator = indicator
      result = renderer.result(binding)
      response, body = http.post(uri.path, result, {'Content-type'=>'text/xml;charset=utf-8'})      
    end

  end
end
