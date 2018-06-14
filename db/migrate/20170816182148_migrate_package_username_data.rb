class MigratePackageUsernameData < ActiveRecord::Migration
	class MPackage < ActiveRecord::Base
    self.table_name = :stix_packages
  end
  class MUser < ActiveRecord::Base
  	self.table_name = :users
  end

  def up
  	packages = MPackage.where(username: nil)

  	packages.find_each do |package|
      user = MUser.where(:guid => package.created_by_user_guid).first
      next if !user.present?
  		package.username = user.username 
  		
	  	begin
		    package.save!
	    rescue StandardError => e
	      puts "Could not change username for package #{package.id}, skipping package. Error: #{e.to_s}"
	      package.save
	    end

	  end
  end

  def down
  end
end
