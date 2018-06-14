namespace :groups do
  task :update => :environment do |*args|
    uperms=0
    cperms=0
    groups=0
    grouperms=0
    # First create permissions
    yml = YAML.load_file('config/permissions.yml')
    (yml[Rails.env]||[]).each do |name,attributes|
      p = Permission.find_by_name(name)
      if p
        change = false
        if p.display_name != attributes['display_name']
          p.display_name = attributes['display_name']
          change = true
        end
        if p.description != attributes['description']
          p.description = attributes['description']
          change = true
        end
        if change
          p.save
          puts "Updated permission "+p.name
          uperms+=1
        end
      else
        p = Permission.new
        p.name = name
        p.display_name = attributes['display_name']
        p.description = attributes['description']
        p.created_at = Time.now
        p.updated_at = Time.now
        p.guid = SecureRandom.uuid
        p.save
        puts "Created permission "+p.name
        cperms+=1
      end
    end
    if uperms==0 && cperms==0
      print "Verified permissions"
    else
      if uperms > 0
        print "Updated "+uperms.to_s+" permission"
        print "s" unless uperms==1
      end
      if cperms > 0
        print "Created "+cperms.to_s+" permission"
        print "s" unless cperms==1
      end
    end
    puts ""
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
        groups+=1
      end
    end
    if groups==0
      print "Verified groups"
    else
      print "Created "+groups.to_s+" group"
      print "s" unless groups==1
    end
    puts ""
    # Now add the proper permissions to each group
    yml.each do |name,attributes|
      g=Group.find_by_name(attributes['name'])
      unless attributes['permissions'].nil?
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
            grouperms+=1
          end
        end

        # Get complete list of current permissions for group
        g=Group.find_by_name(attributes['name'])
        current_permissions=g.permissions.pluck('name')

        # Delete the current permissions from the permission list
        permissions.each do |p|
          current_permissions.delete(p)
        end

        # If a group already has "upload_for_transfer" status and this is a classified system, don't remove it
        if Setting.CLASSIFICATION
          current_permissions.delete('upload_for_transfer')
        end

        # permssions now contains any permissions that do not belong to this group
        current_permissions.each do |name|
          perm=Permission.find_by_name(name)
          GroupPermission.where('permission_id=? and group_id=?',perm.id,g.id).first.delete
        end
      end
    end
    if grouperms==0
      print "Verified group permissions"
    else
      print "Created "+grouperms.to_s+" group permission"
      print "s" unless grouperms==1
    end
    puts

    # Get complete list of current permissions
    perms=[]
    Permission.all.each do |p|
      perms.push(p.name)
    end

    # Delete the permissions in the permissions.yml file
    yml = YAML.load_file('config/permissions.yml')
    (yml[Rails.env]||[]).each do |name,attrs|
      perms.delete(name)
    end

    # perms now contains any permissions that no longer exist
    perms.each do |name|
      perm=Permission.find_by_name(name)
      GroupPermission.where('permission_id=?',perm.id).each do |gp|
        gp.delete
      end
      Permission.delete(perm)
    end
  end
end
