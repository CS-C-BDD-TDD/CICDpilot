namespace :user do
  # Sample:
  # For a non machine user:
  # rake createuser:user username=<username> first=<firstname> last=<lastname> email=<email> groups='Manage System Tags','Modify All Items'
  #
  # For a machine user:
  # rake createuser:user username=<username> first=<firstname> last=<lastname> email=<email> groups='Manage System Tags','Modify All Items' machine=true secret=<secret>
  task :create => :environment do |t, args|
    o = Organization.first || Organization.create!({short_name:'DHS',long_name:'Department of Homeland Security'})
    username = ENV['username']||ENV['USERNAME']
    first = ENV['first']||ENV['FIRST']||ENV['FIRST_NAME']||ENV['first_name']
    last = ENV['last']||ENV['LAST']||ENV['LAST_NAME']||ENV['last_name']
    email = ENV['email']||ENV['EMAIL_ADDRESS']||ENV['EMAIL']||ENV['email_address']
    machine = ENV['machine']||ENV['MACHINE']
    secret = ENV['secret']||ENV['SECRET']
    groups = (ENV['groups']||ENV['GROUPS']).split(',')
    api_key = ENV['api_key']||ENV['API_KEY']
    password = ENV['password']||ENV['PASSWORD']

    groups_ok=true
    groups.each do |group|
      g = Group.find_by_name(group)
      if g.nil?
        groups_ok=false
        puts "#{group} is not a valid group name"
      end
    end
    exit unless groups_ok 

    while (!(password =~ /\A.*(?=.*[a-z])(?=.*[A-Z])(?=.*[\d])(?=.*[\W]).*\z/)) do
      if Setting.MODE == 'CIAP'
        password = SecureRandom.base64(8)
      else
        password = SecureRandom.base64(14)
      end
    end unless password.present?
    user = User.create!(username: username, email: email, first_name: first, last_name: last, organization_guid: o.guid, password: password, password_confirmation: password)
    p = user.passwords.first
    p.requires_change = false
    p.save
    print "User "+username+" created. Password: " + password + "\n"
    groups.each do |group|
      g = Group.find_by_name(group)
      user.groups << g
      print "User "+username+" added to group "+group+"\n"
    end
    user.save

    if api_key.present?
      user.api_key = api_key
      user.save
      user.change_api_key_secret(secret)
      print "API_KEY = "+user.api_key+"\n"
    elsif machine.present?
      user.generate_api_key
      user.change_api_key_secret(secret)
      print "API_KEY = "+user.api_key+"\n"
    end
  end

  task :reenable, [:username] => :environment do |t, args|
    username = args[:username]||ENV['username']||ENV['USERNAME']
    user = User.find_by_username(username)
    if user.present?
      user.update(disabled_at: nil, expired_at: nil, logged_in_at: DateTime.now, locked_at: nil, failed_login_attempts: 0, hidden_at: nil)
    else
      puts "ERROR: Could not find user with username: #{username}"
    end
  end
end
