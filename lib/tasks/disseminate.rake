require 'net/sftp'
require 'stringio'
require 'json'
require 'stix'

namespace :disseminate do
  task :start => :environment do |t, args|
    disseminator_opts = {
        disseminate_yml_path: '/etc/cyber-indicators/config/disseminate.yml',
        disseminate_feeds_yml_path:
            '/etc/cyber-indicators/config/disseminate_feeds.yml',
        stdout_logging: true
    }

    @disseminator = DisseminationService.new(disseminator_opts)

    def connect_to_sftp
      @disseminator.connect_to_sftp
    end

    def write_sftp_file(file, contents)
      @disseminator.write_sftp_file(file, contents)
    end

    def write_api_file(contents, feed)
      @disseminator.write_api_file(contents, feed)
    end

    def write_file(file, contents, feed)
      @disseminator.write_file(file, contents, feed)
    end

    if AppUtilities.is_ecis_dms_1c_arch? &&
        Setting.DISSEMINATION_QUEUE_PROCESSOR_FREQUENCY_IN_MINUTES.to_i > 0
      @disseminator.log_warn('The amqp-receiver service is configured to process dissemination queue records so this dissemination engine rake task will now exit.')
    else
      @disseminator.disseminate_files
    end
  end

  task :test_flare_api => :environment do |t, args|
    disseminator_opts = {
        disseminate_yml_path: '/etc/cyber-indicators/config/disseminate.yml',
        disseminate_feeds_yml_path:
            '/etc/cyber-indicators/config/disseminate_feeds.yml',
        stdout_logging: true
    }

    @disseminator = DisseminationService.new(disseminator_opts)

    def write_api_file(contents, feed)
      @disseminator.write_api_file(contents, feed)
    end

    unless ENV['FILE'] && ENV['FILE'].length > 0
      puts "FILE not specified."
      exit 1
    end
    unless File.exist?(ENV['FILE'])
      puts "The file specified: \"#{ENV['FILE']}\" does not exist."
      exit 1
    end
    unless ENV['FEED'] && ENV['FEED'].length > 0
      puts "FEED not specified."
      exit 1
    end
    unless @FEEDS[ENV['FEED']]
      puts "FEED \"#{ENV['FEED']}\" does not exist."
      exit 1
    end
    contents=File.open(ENV['FILE'],'rb:utf-8').read
    if write_api_file(contents, ENV['FEED'])
      puts "File \"#{ENV['FILE']}\" successfully sent to the #{ENV['FEED']} feed."
    else
      puts "Problem sending file \"#{ENV['FILE']}\" to the #{ENV['FEED']} feed."
    end
  end
end
