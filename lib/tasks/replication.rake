namespace :replication do
  def create(url = ENV['URL'], type = ENV['TYPE'], api_key = ENV['API_KEY'], api_key_hash = ENV['API_KEY_HASH'])
    url = url || "https://localhost:8443"

    if ENV['URL'].match('localhost') || 
       ENV['URL'].match(Socket.gethostname) ||
       Socket.ip_address_list.map(&:inspect_sockaddr).select {|addr| ENV['URL'].match addr }.any?
      puts "WARNING: You may be configuring a replication loop."
      puts "  The URL you entered #{ENV['URL']} appears to match this systems address."
      puts "  This can create a replication loop.  Is this what you intend to do?"
      puts "  You may view the current replications with rake replication:list"
      ReplicationLogger.debug("[replication][create]: WARNING: Potential replication loop detected.")
    end 

    replication = Replication.create url: url,api_key: api_key, api_key_hash: api_key_hash,repl_type: type
    ReplicationLogger.debug("[replication][create]: id: #{replication.id},api_key: #{replication.api_key},api_key_hash: #{replication.api_key_hash},repl_type: #{replication.repl_type}")
  end
  task :create => :environment do
    create()
    puts "done."
  end

  task :create_public_release => :environment do
    url = ENV['URL']
    types = { indicators: "#{url}/cyber-indicators/indicators",
              observables: "#{url}/cyber-indicators/observables",
              dns_records: "#{url}/cyber-indicators/dns_records",
              domains: "#{url}/cyber-indicators/domains",
              email_messages: "#{url}/cyber-indicators/email_messages",
              files: "#{url}/cyber-indicators/files",
              http_sessions: "#{url}/cyber-indicators/http_sessions",
              addresses: "#{url}/cyber-indicators/addresses",
              mutexes: "#{url}/cyber-indicators/mutexes",
              network_connections: "#{url}/cyber-indicators/network_connections",
              registries: "#{url}/cyber-indicators/registries",
              uris: "#{url}/cyber-indicators/uris" }
    types.each_pair { |key,value| 
      create(value,key,ENV['API_KEY'],ENV['API_KEY_HASH'])
    }
  end
  
  task :create_weathermap => :environment do
    url = ENV['URL']
    types = { weathermap: "#{url}/cyber-indicators/ipreputation",
              heatmap: "#{url}/cyber-indicators/heatmaps" }
    types.each_pair { |key,value| 
      create(value,key,ENV['API_KEY'],ENV['API_KEY_HASH'])
    }
  end

  task :create_stix_forward => :environment do
    url = ENV['URL']
    types = { stix_forward: "#{url}/cyber-indicators/uploads?forward=N" }
    types.each_pair { |key,value|
      create(value,key,ENV['API_KEY'],ENV['API_KEY_HASH'])
    }
  end

  task :create_publish => :environment do
    url = ENV['URL']
    types = { publish: "#{url}/cyber-indicators/uploads?overwrite=Y&forward=N" }
    types.each_pair { |key,value|
      create(value,key,ENV['API_KEY'],ENV['API_KEY_HASH'])
    }
  end

  task :create_ais_statistic_forward => :environment do
    url = ENV['URL']
    types = { ais_statistic_forward: "#{url}/cyber-indicators/ais_statistics" }
    types.each_pair { |key,value|
      create(value,key,ENV['API_KEY'],ENV['API_KEY_HASH'])
    }
  end

  task :update => :environment do
    id = ENV["ID"] 
    replication = Replication.find id
    url = ENV["URL"] || replication.url
    api_key = ENV["API_KEY"] || replication.api_key
    api_key_hash = ENV["API_KEY_HASH"] || replication.api_key_hash
    type = ENV["TYPE"] || replication.repl_type
    replication.update_attributes({url: url,api_key: api_key,api_key_hash: api_key_hash,last_status: "MODIFIED",repl_type: type})
    ReplicationLogger.debug("[replication][update]: id: #{replication.id},api_key: #{replication.api_key},api_key_hash: #{replication.api_key_hash},repl_type: #{replication.repl_type}")
    puts "done."
  end

  task :list => :environment do
    puts "ID\tLAST_STATUS\tLAST_UPDATE\tTYPE\tURL\t\tAPI_KEY"
    replications = if ENV['TYPE'].present?
      Replication.where(repl_type: ENV['TYPE'])
    else
      Replication.all
    end
    replications.each do |replication|
      puts "#{replication.id}\t#{replication.last_status || 'NEW'}\t#{replication.updated_at || 'NEVER'}\t#{replication.repl_type || "NONE"}\t#{replication.url}\t#{replication.api_key}"
    ReplicationLogger.debug("[replication][list]: id: #{replication.id},api_key: #{replication.api_key},api_key_hash: #{replication.api_key_hash},repl_type: #{replication.repl_type} last_status: #{replication.last_status} updated_at: #{replication.updated_at}")
    end
  end
  
  task :dup => :environment do
    replication = Replication.find ENV['ID']
    new_replication = replication.dup
    new_replication.save
  end

  task :destroy => :environment do
    Replication.destroy ENV['ID']||ENV['id']
  end
  
  task :destroy_all => :environment do
    Replication.destroy_all
  end

  task :test => :environment do
    replications = if ENV['ID'].present?
      Replication.where id: ENV['ID']
    else
      Replication.all
    end
    replications.map &:test 
  end
  
  namespace :test do
    task :post => :environment do
      replications = if ENV['ID'].present?
        Replication.where id: ENV['ID']
      else
        Replication.all
      end

      replications.each do |replication|
        if replication.last_status == "OK"
          replication.test_post
          next
        end
        puts "Cannot test Replication ID: #{replication.id}: LAST_STATUS must be OK before testing POST."
        puts "  Please ensure that rake replication:test succeeds first."
      end
    end
  end

end
