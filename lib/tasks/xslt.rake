namespace :xslt do
  task :transform, [:filename] => :environment do |t, args|
    if args[:filename]
      f=File.open(args[:filename])
      xml=f.read
      f.close
      package_info=Stix::Stix111::PackageInfo.extract_package_info(xml)
      transformer=Stix::Xslt::Transformer.new
      xml_isa=transformer.transform_stix_xml(xml, 'isa', 'EVERYONE',
                                             package_info.is_federal, true)
      if xml_isa.present?
        xml_isa = xml_isa.force_encoding('UTF-8')
      else
        puts 'ISA PROFILE TRANSFORMATION ERRORS:'
        puts transformer.errors
      end
      xml_ais=transformer.transform_stix_xml(xml, 'ais', 'EVERYONE',
                                             package_info.is_federal, false)
      if xml_ais.present?
        xml_ais = xml_ais.force_encoding('UTF-8')
      else
        puts 'AIS PROFILE TRANSFORMATION ERRORS:'
        puts transformer.errors
      end
      if xml_isa.present?
        isa_filename=args[:filename].gsub('.xml','_isa.xml')
        f=File.open(isa_filename, 'w:utf-8')
        f.write(xml_isa)
        f.close
        puts "Output ISA file to #{isa_filename}"
      end
      if xml_ais.present?
        ais_filename=args[:filename].gsub('.xml','_ais.xml')
        f=File.open(ais_filename, 'w:utf-8')
        f.write(xml_ais)
        f.close
        puts "Output AIS file to #{ais_filename}"
      end
    else
      puts "Filename is required"
    end
  end
end
