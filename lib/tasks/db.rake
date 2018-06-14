require 'active_record'
require 'erb'

namespace :db do

  task :grant => :environment do

    abort 'Must be run in the dbadmin environment' if ::Rails.env != 'dbadmin'

    db_config = ActiveRecord::Base.configurations

    production_db_adapter = db_config['production']['adapter']
    dbadmin_db_adapter    = db_config['dbadmin']['adapter']
    if (production_db_adapter != 'postgresql' and
        dbadmin_db_adapter != 'postgresql') &&
       (production_db_adapter != 'oracle_enhanced' and
        dbadmin_db_adapter != 'oracle_enhanced')
      abort 'Oracle or PostgreSQL must be used in production/dbadmin environments.'
    end

    production_db_name = db_config['production']['database']
    dbadmin_db_name    = db_config['dbadmin']['database']
    if production_db_name != dbadmin_db_name
      abort 'Database must be the same for production and dbadmin environments.'
    end

    puts 'Adjusting permissions on production database for production user.'
    ActiveRecord::Base.establish_connection(::Rails.env.to_sym)
    connection = ActiveRecord::Base.connection

    if production_db_adapter == 'oracle_enhanced' 
      fix_oracle_permissions(connection)
    else
      fix_postgres_permissions(connection, db_config['production']['username'])
    end

    ActiveRecord::Base.remove_connection
  end

  def fix_oracle_permissions(connection)
    connection.execute('BEGIN grant_privs; END;')
  end

  def fix_postgres_permissions(connection, prod_app_user)
    tables = connection.tables
    tables.delete('schema_migrations')
    tables.delete_if { |t| t =~ /old/ }
    sql = ''
    tables.each do |table|
      sql = sql + "GRANT SELECT, INSERT, UPDATE, DELETE ON #{table} TO #{prod_app_user};\n"
      sql = sql + "GRANT SELECT, UPDATE ON SEQUENCE #{table}_id_seq TO #{prod_app_user};\n"
    end
    connection.execute(sql)
  end

  task :synonyms => :environment do
    abort 'Must be run in the production environment' if ::Rails.env != 'production'
    ActiveRecord::Base.establish_connection(::Rails.env.to_sym)
    connection = ActiveRecord::Base.connection
    connection.execute('BEGIN create_synonyms; END;')
  end

  namespace :template do
    task :create => :environment do |t,args|
      template = ENV['TEMPLATE']
      renderer = ERB.new(File.read(template))
      result = renderer.result()
      outfile = ENV['OUTFILE']
      of = File.open(outfile,'w') { |f|
        f.puts result
      }
      puts "Created #{outfile}"
    end
  end


end
