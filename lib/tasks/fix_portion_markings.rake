namespace :fix_portion_markings do
  task :stix_packages => :environment do
    total_groups = StixPackage.count / 1000
    StixPackage.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end

  task :indicators => :environment do
    total_groups = Indicator.count / 1000
    Indicator.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end

  task :threat_actors => :environment do
    total_groups = ThreatActor.count / 1000
    ThreatActor.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end

  task :ttps => :environment do
    total_groups = Ttp.count / 1000
    Ttp.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end

  task :courses_of_action => :environment do
    total_groups = CourseOfAction.count / 1000
    CourseOfAction.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end

  task :vulnerabilities => :environment do
    total_groups = Vulnerability.count / 1000
    Vulnerability.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end
  
  task :attack_patterns => :environment do
    total_groups = AttackPattern.count / 1000
    AttackPattern.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end
  
  task :addresses => :environment do
    total_groups = Address.count / 1000
    Address.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end
  
  task :dns_queries => :environment do
    total_groups = DnsQuery.count / 1000
    DnsQuery.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end
  
  task :dns_records => :environment do
    total_groups = DnsRecord.count / 1000
    DnsRecord.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end
  
  task :domains => :environment do
    total_groups = Domain.count / 1000
    Domain.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end
  
  task :email_messages => :environment do
    total_groups = EmailMessage.count / 1000
    EmailMessage.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end
  
  task :files => :environment do
    total_groups = CyboxFile.count / 1000
    CyboxFile.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end
  
  task :hostnames => :environment do
    total_groups = Hostname.count / 1000
    Hostname.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end
  
  task :http_sessions => :environment do
    total_groups = HttpSession.count / 1000
    HttpSession.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end
  
  task :links => :environment do
    total_groups = Link.count / 1000
    Link.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end
  
  task :mutexes => :environment do
    total_groups = CyboxMutex.count / 1000
    CyboxMutex.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end
  
  task :network_connections => :environment do
    total_groups = NetworkConnection.count / 1000
    NetworkConnection.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end
  
  task :ports => :environment do
    total_groups = Port.count / 1000
    Port.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end
  
  task :registries => :environment do
    total_groups = Registry.count / 1000
    Registry.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end
  
  task :socket_addresses => :environment do
    total_groups = SocketAddress.count / 1000
    SocketAddress.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end
  
  task :uris => :environment do
    total_groups = Uri.count / 1000
    Uri.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end
  
  task :questions => :environment do
    total_groups = Question.count / 1000
    Question.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end
  
  task :resource_records => :environment do
    total_groups = ResourceRecord.count / 1000
    ResourceRecord.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          obj.set_portion_marking
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end
  
  task :questions_remove_pm => :environment do
    total_groups = Question.count / 1000
    Question.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          short_cache = obj.qname_cache
          if short_cache[0..3].include?("(") && Setting.CLASSIFICATION == false
            short_cache = short_cache[4..short_cache.length]
            obj.update_column(:qname_cache, short_cache)
          end
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end
  
  task :resource_records_remove_pm => :environment do
    total_groups = ResourceRecord.count / 1000
    ResourceRecord.find_in_batches.with_index do |group, batch|
      puts "Processing Object group ##{batch+1} of ##{total_groups+1}"
      group.each do |obj|
        begin
          short_cache = obj.dns_record_cache
          if short_cache[0..3].include?("(") && Setting.CLASSIFICATION == false
            short_cache = short_cache[4..short_cache.length]
            obj.update_column(:dns_record_cache, short_cache)
          end
        rescue Exception => e
          puts "Could not reset portion marking on #{obj.id}, skipping, Error: #{e.to_s}"
        end
      end
    end
    puts "done."
  end

end
