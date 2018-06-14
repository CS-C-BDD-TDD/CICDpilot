namespace :machineuser do
  task :set, [:username] => :environment do |t, args|
    username = args[:username]
    user = User.find_by_username(username)
    user.machine = true
    user.save
  end

  task :unset, [:username] => :environment do |t, args|
    username = args[:username]
    user = User.find_by_username(username)
    user.machine = false
    user.save
  end
end
