require 'rubygems/package'
require 'zlib'
require 'csv'

namespace :weather do
  namespace :import do
    task :dir, [:dir, :username, :should_replicate] => :environment do |t, args|
      should_replicate = true_or_false(args.should_replicate)
      if should_replicate.nil?
        puts "Third argument should be 'true' or 'false'"
        exit
      end
      num_files = 0
      Dir.glob("#{args.dir}/*.{csv,gz}") do |csv_file|
        import_file(csv_file,args.username,should_replicate)
        num_files = num_files + 1
      end
      if num_files == 0
        msg = "[WeatherMapRakeTask][weather:import:dir] No files found in #{args.dir}"
        puts msg
        WeatherMapLogger.warn(msg)
      end
    end
    task :file, [:filename, :username, :should_replicate] => :environment do |t, args|
      should_replicate = true_or_false(args.should_replicate)
      if should_replicate.nil?
        puts "Third argument should be 'true' or 'false'"
        exit
      end
      import_file(args.filename, args.username, should_replicate)
    end
    def true_or_false(value)
      retval=nil
      if value=~/true/i
        retval=true
      elsif value=~/false/i
        retval=false
      end
      retval
    end
    def import_file(filename, username, should_replicate)
      if filename.nil?
        msg = "[WeatherMapRakeTask][import_file] You need to specify a filename.  rake weather:import:indicators[data.csv, weatherman]"
        puts msg
        WeatherMapLogger.error(msg)
        return
      end
      msg = "[WeatherMapRakeTask][import_file] Importing #{filename} as #{username}"
      puts msg
      WeatherMapLogger.info(msg)
      if filename.end_with? ".csv"
        import_csv(filename, username, should_replicate)
      elsif filename.end_with?(".tar.gz") || filename.end_with?(".tgz")
        import_tar_gz(filename, username, should_replicate)
      elsif filename.end_with? ".gz"
        import_gz(filename, username, should_replicate)
      else
        msg = "[WeatherMapRakeTask][import_file] The filename must end with csv or gz"
        puts msg
        WeatherMapLogger.error(msg)
        return
      end
    end
    def import_tar_gz(filename, username, should_replicate)
      csv_data = ""
      tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(filename))
      tar_extract.rewind # The extract has to be rewinded after every iteration
      tar_extract.each do |entry|
        if entry.file?
          csv_data = entry.read
          import_csv_data(csv_data, username, should_replicate)
        end
      end
      tar_extract.close
    end
    def import_gz(filename, username, should_replicate)
      csv_data = ""
      Zlib::GzipReader.open(filename) do |gz|
        csv_data = gz.read
      end
      import_csv_data(csv_data, username, should_replicate)
    end
    def import_csv(filename, username, should_replicate)
      begin
        file = File.open(filename, "rb")
      rescue Errno::ENOENT
        msg = "[WeatherMapRakeTask][import_csv] Could not find file #{filename} in #{Dir.pwd}"
        puts msg
        WeatherMapLogger.error(msg)
        return
      end
      csv_data = file.read
      import_csv_data(csv_data, username, should_replicate)
    end
    def import_csv_data(csv_data, username, should_replicate)
      if username.nil?
        msg = '[WeatherMapRakeTask][import_file] You need to specify a username who will "perform" the upload.  rake weather:import:indicators[data.csv, weatherman]'
        puts msg
        WeatherMapLogger.error(msg)
        return
      end
      user = User.find_by_username username
      if user.nil?
        msg = "[WeatherMapRakeTask][import_file] No user with username #{username}"
        puts msg
        WeatherMapLogger.error(msg)
        return
      end
      User.current_user = user
      ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)
      data_type = determine_data_type(csv_data)
      total_good,rejects,created_ids = (data_type == 'Address') ? Address.create_weather_map_data(csv_data) : Domain.create_weather_map_data(csv_data)
      if should_replicate
        replications = Replication.where(repl_type:'weathermap')
        num_replicated = 0
        replication_status = replications.map do |replication|
          msg = "[WeatherMapRakeTask][import_file] Replicating: ID: #{replication.id} URL: #{replication.url}"
          puts msg
          WeatherMapLogger.info(msg)
          replication.send_data(csv_data,{"Content-type"=>'text/csv'})
          num_replicated = num_replicated + 1
        end
        replication_status = replication_status.all?
        if num_replicated == 0
          msg = "[WeatherMapRakeTask][import_file] The script was asked to replicate weather map data, but no configuration endpoint for replication has been set."
          puts msg
          WeatherMapLogger.error(msg)
        end
        msg = "[WeatherMapRakeTask][import_file] Replicated: replication_status: #{replication_status}"
        puts msg
        WeatherMapLogger.info(msg)
        objects = (data_type == 'Address') ? (Address.where id: created_ids) : (Domain.where id: created_ids)
        objects.update_all replicated: replication_status,replicated_at: Time.now
      end
      ::Sunspot.session = ::Sunspot.session.original_session
    end
    # Wrapper to call the right weather_map_data creation depending on type
    def determine_data_type(csv_data)
      CSV.parse(csv_data) do |row|
        # skip blank lines
        next if row.count == 0
        next if row.count != 9        
        return (Address.valid_ipv4_value?(row[0]) || Address.valid_ipv6_value?(row[0])) ? 'Address' : 'Domain'
      end
      nil
    end
  end

  task :acs_set => :environment do |t, args|
    isa_assertion = IsaAssertionStructure.new(AcsDefault::ASSERTION_DEFAULTS)

    # We set the Assertion Defaults to blank on classified systems for ui purposes.
    # this will cause these markings to be invalid when generating.  So we set it back to U
    isa_assertion.cs_classification = 'U'

    isa_privs = AcsDefault::PRIVS_DEFAULTS.collect do |priv|
      IsaPriv.new(priv)
    end
    stix_marking = StixMarking.new(
        is_reference: false
    )
    stix_marking.isa_assertion_structure = isa_assertion
    stix_marking.isa_assertion_structure.isa_privs = isa_privs

    wm_set = AcsSet.new(name: 'Default Markings for Weather Map',locked: true)
    wm_set.stix_markings << stix_marking
    wm_set.save
    puts wm_set.id
  end

  task :purge_addresses => :environment do
    count=0
    addresses=Address.where("updated_at < (sysdate-60)").where("combined_score is not null").where("cybox_object_id not in (select distinct remote_object_id from cybox_observables)")
    addresses.in_groups_of(1000, false) do |a|
      count+=a.count
      Sunspot.remove_by_id!(:Address,a.map(&:id))
    end
    addresses.delete_all
    puts "Purged #{count} records"
  end

  task :purge_domains => :environment do
    count=0
    domains=Domain.where("updated_at < (sysdate-60)").where("combined_score is not null").where("cybox_object_id not in (select distinct remote_object_id from cybox_observables)")
    domains.in_groups_of(1000, false) do |d|
      count+=d.count
      Sunspot.remove_by_id!(:Domain,d.map(&:id))
    end
    domains.delete_all
    puts "Purged #{count} records"
  end

  task :index => :environment do |t, args|
    from = if ENV['FROM']
      DateTime.parse(ENV['FROM'])
    else
      1.year.ago
    end.beginning_of_day

    to = if ENV['TO']
      DateTime.parse(ENV['TO'])
    else
      Date.today
    end.end_of_day

    types = ENV['TYPES'].split(',')

    types.each do |type|
      indexed = 0
      starttime = lasttime = Time.now.to_i
    
      if type.capitalize=='I'
        model='Indicator'
      elsif type.capitalize=='A'
        model='Address'
      elsif type.capitalize=='D'
        model='Domain'
      else
        puts "Environment variable TYPES only responds to i, a or d."
        exit
      end
    
      puts ("Indexing #{model.pluralize} from: #{from} to: #{to}...")
      total=model.constantize.where('created_at>=?',from).where('created_at<=?',to).pluck(:id).count

      model.constantize.where('created_at>=?',from).where('created_at<=?',to).find_in_batches { |batch|
        Sunspot.index(batch)
        indexed+=batch.count
        total_diff = timediff(starttime)
        last_diff = timediff(lasttime)
        lasttime = Time.now.to_i
        puts "  #{indexed} #{model.pluralize} indexed out of #{total} (#{percent(indexed,total)}%)  #{last_diff}/#{total_diff}"
      }
      puts "Done."
    end
  end

  task :verify => :environment do |t, args|
    Sunspot.config.pagination.default_per_page=255

    from = if ENV['FROM']
      DateTime.parse(ENV['FROM'])
    else
      1.year.ago
    end.beginning_of_day

    to = if ENV['TO']
      DateTime.parse(ENV['TO'])
    else
      Date.today
    end.end_of_day

    env_count=100
    if ENV['COUNT']
      env_count=ENV['COUNT'].to_i
    end

    types = ENV['TYPES'].split(',')

    types.each do |type|
      total=indexed=new=0
      starttime = lasttime = Time.now.to_i

      if type.capitalize=='I'
        model='Indicator'
        values='id,title'
      elsif type.capitalize=='A'
        model='Address'
        values='id,address_value_raw'
      elsif type.capitalize=='D'
        model='Domain'
        values='id,name_raw'
      else
        puts "Environment variable TYPES only responds to i, a or d."
        exit
      end

      puts ("Verifying #{model.pluralize} from: #{from} to: #{to}...")
      object_ids = model.constantize.where('created_at >= ?',from).where('created_at <= ?',to).pluck(values)

      total_objs = object_ids.count

      object_ids.each do |id|
        total+=1;
        if type.capitalize=='I'
          if check_indicator(id[0],id[1])
            puts "  #{id[1]}" if ENV['VERBOSE']
            indexed+=1
          else
            i=Indicator.find(id[0])
            i.index
            new+=1
          end
        end
        if type.capitalize=='A'
          if check_address(id[0],id[1])
            puts "  #{id[1]}" if ENV['VERBOSE']
            indexed+=1
          else
            a=Address.find(id[0])
            a.index
            new+=1
          end
        end
        if type.capitalize=='D'
          if check_domain(id[0],id[1])
            puts "  #{id[1]}" if ENV['VERBOSE']
            indexed+=1
          else
            a=Domain.find(id[0])
            a.index
            new+=1
          end
        end
        if total%env_count==0
          total_diff = timediff(starttime)
          last_diff = timediff(lasttime)
          lasttime = Time.now.to_i
          puts "  #{indexed} #{model.pluralize}, #{new} new are indexed out of #{total}/#{total_objs} (#{percent(total,total_objs)}%)  #{last_diff}/#{total_diff}"
        end
      end
      if total%env_count
        total_diff = timediff(starttime)
        last_diff = timediff(lasttime)
        lasttime = Time.now.to_i
        puts "  #{indexed} #{model.pluralize}, #{new} new are indexed out of #{total}/#{total_objs} (#{percent(total,total_objs)}%)  #{last_diff}/#{total_diff}"
      end
      puts "Done."
    end
  end

  def check_indicator(id,title)
    search=Indicator.search do
      fulltext title
    end
    check=false
    search.results.each do |s|
      if s.id==id
        check=true
      end
    end
    check
  end

  def check_address(id,ip)
    search=Address.search do
      keywords(ip,fields: :address)
    end
    check=false
    search.results.each do |s|
      if s.id==id
        check=true
      end
    end
    check
  end

  def check_domain(id,name)
    search=Domain.search do
      keywords(name,fields: :domain)
    end
    check=false
    search.results.each do |s|
      if s.id==id
        check=true
      end
    end
    check
  end

  def timediff( starttime )
    currenttime = Time.now.to_i
    diff = currenttime - starttime
    hours = diff / 3600
    minutes = ( diff - ( hours * 3600 ) ) / 60
    seconds = diff - ( hours * 3600 ) - ( minutes * 60 )
    return '%d:%02d:%02d' % [ hours.to_s, minutes.to_s, seconds.to_s ]
  end

  def percent(count,total)
    result = (((count.to_f/total)*1000).to_int)/10.0
    result
  end
end
