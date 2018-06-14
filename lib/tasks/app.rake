namespace :app do
  task :bootstrap => :environment do
    # First create permissions
    yml = YAML.load_file('config/permissions.yml')
    (yml[Rails.env]||[]).each do |name,attributes|
      unless Permission.find_by_name(name)
        p = Permission.new
        p.name = name
        p.display_name = attributes['display_name']
        p.description = attributes['description']
        p.created_at = Time.now
        p.updated_at = Time.now
        p.guid = SecureRandom.uuid
        p.save
        puts "Created permission "+p.name
      end
    end
    # Now create groups with the proper permissions
    yml = YAML.load_file('config/groups.yml')
    yml.each do |name,attributes|
      unless Group.find_by_name(attributes['name'])
        g=Group.new
        g.name = attributes['name']
        g.description = attributes['description']
        g.created_at = Time.now
        g.updated_at = Time.now
        g.guid = SecureRandom.uuid
        g.save
        puts "Created group "+g.name
      end
    end
    # Now add the proper permissions to each group
    yml.each do |name,attributes|
      g=Group.find_by_name(attributes['name'])
      unless attributes['permissions'].nil?
        perms=[]
        permissions=attributes['permissions'].strip.split /\s+/
        permissions.each do |permission|
          p=Permission.find_by_name(permission)
          if GroupPermission.where("group_id=? and permission_id=?",g.id,p.id).empty?
            gp=GroupPermission.new
            gp.group_id = g.id
            gp.permission_id = p.id
            gp.created_at = Time.now
            gp.guid = SecureRandom.uuid
            gp.save
            puts "Added "+p.name+" to "+g.name
          end
        end
      end
    end

    results = Organization.where(short_name: 'NSD', long_name: 'Network Security Deployment')
    if results.empty?
      # hard coding guid so it matches across versions
      o = Organization.create!(short_name: 'NSD', long_name: 'Network Security Deployment', guid: '949e30ce-400f-4b06-b0d6-dd75057eb8a9')
    else
      o = results.first
    end
    if Rails.env == 'production'
      pw = 'P@ssw0rd!12345'
    else
      pw = 'P@ssw0rd!'
    end

    user = User.new(username:'svcadmin',
                    first_name:'Cyber Indicators',
                    last_name:'Administrator',
                    email:'svcadmin@cyber.indicators.gov',
                    password: pw,
                    password_confirmation: pw,
                    organization: o,
                    terms_accepted_at: Time.now)

    if User.find_by_username(user.username)
      puts "User: #{user.username} already exists."
    else
      user.save
      puts "User: #{user.username} created."
      puts "  !Important! #{user.username} created with a default password \"#{pw}\".  Please change this password as soon as possible."
    end

    user = User.find_by_username(user.username)

    group = Group.find_by_name('Admin')

    if user.groups.find_by_name(group.name)
      puts "Group Assignment: \"#{user.username}\" is already a member of group \"#{group.name}\"."
    else
      user.groups << group
      user.save
      puts "Group Assignment: Assigned \"#{user.username}\" to group \"#{group.name}\"."
    end

    password = user.passwords.first
    password.requires_change = false
    password.save

    Rake::Task['weather:acs_set'].execute
  end
end
