task :check_ts => :environment do |t, args|
  puts "BANNER_COLOR: #{Setting.BANNER_COLOR}"
  puts "BANNER_TEXT: #{Setting.BANNER_TEXT}"
  puts "BANNER_TEXT_COLOR: #{Setting.BANNER_TEXT_COLOR}"
  puts "CLASSIFICATION: #{Setting.CLASSIFICATION}"
  puts "READ_ONLY_EXT: #{Setting.READ_ONLY_EXT}"
  puts
  if Setting.BANNER_COLOR==nil
    print "BANNER_COLOR setting does not exist\n".red
  end
  if Setting.BANNER_TEXT==nil
    print "BANNER_TEXT setting does not exist\n".red
  end
  if Setting.BANNER_TEXT_COLOR==nil
    print "BANNER_TEXT_COLOR setting does not exist\n".red
  end
  if Setting.CLASSIFICATION==nil
    print "CLASSIFICATION setting does not exist\n".red
  elsif Setting.CLASSIFICATION!=true
    print "CLASSIFICATION setting is incorrect, should be true\n".red
  end
  if Setting.READ_ONLY_EXT==nil
    print "READ_ONLY_EXT setting does not exist\n".red
  end
  if File.file?('/etc/cyber-indicators/tomcat7/conf/server.xml')
    server = IO.read('/etc/cyber-indicators/tomcat7/conf/server.xml')
    server =~ /<Connector port="8443"(.+?)\/>/m
    ciap_connector = $1
    if ciap_connector !~ /sslEnabledProtocols="TLSv1.2"/ || ciap_connector !~ /sslProtocol="TLS"/
      print "server.xml does not contain the TLSv1.2 entry for port 8443\n".red
    end
  else
    print "server.xml file does not exist\n".red
  end
end
