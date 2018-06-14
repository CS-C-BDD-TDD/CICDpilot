namespace :sunspot do
  namespace :reindex do
    task :since => :environment do
      since = if ENV['SINCE']
        DateTime.parse(ENV['SINCE'])
      else
        1.year.ago
      end

      object = ENV['OBJECT'] || 'Indicator'
      puts ("Reindexing #{object.pluralize} since: #{since}...")
      objects = (object.constantize).where('updated_at > ?',since)
      objects.all.each do |object|
        if ENV['VERBOSE']
          puts "  reindexing id: #{object.id}"
        end

        response = object.solr_remove_from_index!

        if ENV['STATUS']
          puts "Response: #{response}"
        end

        response = object.solr_index!

        if ENV['STATUS']
          puts "Response: #{response}"
        end
      end

      Sunspot.commit

    end

    task :range => :environment do
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

      object = ENV['OBJECT'] || 'Indicator'
      puts ("Reindexing #{object.pluralize} from: #{from} to: #{to}...")
      objects = (object.constantize).where('updated_at >= ?',from).where('updated_at <= ?',to).order(updated_at: :desc)

      count=0

      env_count=ENV['COUNT'].to_i

      objects.all.each do |obj|
        if ENV['VERBOSE']
          puts "  reindexing id: #{obj.id}"
        end

        response = obj.solr_remove_from_index!

        if ENV['STATUS']
          puts "Response: #{response}"
        end

        response = obj.solr_index!

        if ENV['STATUS']
          puts "Response: #{response}"
        end

        count += 1
        if ENV['COUNT']
          if (count%env_count==0)
            puts "  Reindexed #{count} #{object.pluralize}"
          end
        end
      end

      if ENV['COUNT']
        if (count%env_count)
          puts "  Reindexed #{count} #{object.pluralize}"
        end
      end

      Sunspot.commit

      puts "Reindexing of #{object.pluralize} Complete"

    end

    task :model => :environment do
      puts "Reindexing "+ENV['MODEL']
      ENV['MODEL'].constantize.solr_reindex(:batch_size => 1000)
    end
  end

  task :drop => :environment do
    puts "Removing "+ENV['MODEL']+" from SOLR"
    Sunspot.remove_all!(ENV['MODEL'].constantize)
  end

  task :optimize => :environment do
    puts "Optimizing SOLR indexes"
    Sunspot.optimize
  end
end

