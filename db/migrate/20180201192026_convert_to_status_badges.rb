class ConvertToStatusBadges < ActiveRecord::Migration
  class MPackage < ActiveRecord::Base 
    self.table_name = 'stix_packages'
    include Auditable
  end

  def create_status_badge(parent, badge_name, status=nil, system=false)
    badge = BadgeStatus.new
    badge.remote_object = parent
    badge.badge_name = badge_name
    badge.badge_status = status
    badge.system = system
    badge.remote_object_type = "StixPackage"
    begin
      badge.save!
    rescue Exception => e
      ExceptionLogger.debug("exception: #{e}, message: #{e.message}, backtrace: #{e.backtrace}")
    end

    badge
  end

  def up
    # MIFR, CISCP, UPLOADED, FEEDS
    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)
    ActiveRecord::Base.record_timestamps = false

    total_groups = MPackage.where(:is_mifr => true).count / 1000
    MPackage.where(:is_mifr => true).find_in_batches.with_index do |group, batch|
      puts "Processing MIFRs group ##{batch+1} of #{total_groups+1}"
      group.each do |object|
        badge_names = BadgeStatus.where(:remote_object_id => object.guid).collect(&:badge_name)
        begin
          if badge_names.exclude?("MIFR")
            create_status_badge(object, "MIFR", nil, true)
          end
        rescue Exception => e
          puts "Could not transition #{object.id}, skipping Package. Error: #{e.to_s}"
        end
      end
    end

    total_groups = MPackage.where(:is_ciscp => true).count / 1000
    MPackage.where(:is_ciscp => true).find_in_batches.with_index do |group, batch|
      puts "Processing CISCP group ##{batch+1} of #{total_groups+1}"
      group.each do |object|
        badge_names = BadgeStatus.where(:remote_object_id => object.guid).collect(&:badge_name)
        begin
          if badge_names.exclude?("CISCP")
            create_status_badge(object, "CISCP", nil, true)
          end
        rescue Exception => e
          puts "Could not transition #{object.id}, skipping Package. Error: #{e.to_s}"
        end
      end
    end

    total_groups = MPackage.where.not(:uploaded_file_id => nil).count / 1000
    MPackage.where.not(:uploaded_file_id => nil).find_in_batches.with_index do |group, batch|
      puts "Processing Uploaded Badge group ##{batch+1} of #{total_groups+1}"
      group.each do |object|
        badge_names = BadgeStatus.where(:remote_object_id => object.guid).collect(&:badge_name)
        begin
          if badge_names.exclude?("UPLOADED")
            create_status_badge(object, "UPLOADED", nil, true)
          end
        rescue Exception => e
          puts "Could not transition #{object.id}, skipping Package. Error: #{e.to_s}"
        end
      end
    end

    total_groups = MPackage.where.not(:feeds => nil).count / 1000
    MPackage.where.not(:feeds => nil).find_in_batches.with_index do |group, batch|
      puts "Processing Uploaded Badge group ##{batch+1} of #{total_groups+1}"
      group.each do |object|
        badge_names = BadgeStatus.where(:remote_object_id => object.guid).collect(&:badge_name)
        begin
          package_feeds = object.feeds.split(",")
          package_feeds.each do |x|
            if badge_names.exclude?(x)
              create_status_badge(object, x, nil, true)
            end
          end
        rescue Exception => e
          puts "Could not transition #{object.id}, skipping Package. Error: #{e.to_s}"
        end
      end
    end

    ActiveRecord::Base.record_timestamps = true
    ::Sunspot.session = ::Sunspot.session.original_session
  end

  def down
    # MIFR, CISCP, UPLOADED, FEEDS
    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)
    ActiveRecord::Base.record_timestamps = false

    total_groups = MPackage.where(:is_mifr => true).count / 1000
    MPackage.where(:is_mifr => true).find_in_batches.with_index do |group, batch|
      puts "Processing MIFRs group ##{batch+1} of #{total_groups+1}"
      group.each do |object|
        badge_names = BadgeStatus.where(:remote_object_id => object.guid).collect(&:badge_name)
        begin
          if badge_names.include?("MIFR")
            BadgeStatus.where(:remote_object_id => object.guid, :badge_name => "MIFR").delete_all
          end
        rescue Exception => e
          puts "Could not transition #{object.id}, skipping Package. Error: #{e.to_s}"
        end
      end
    end

    total_groups = MPackage.where(:is_ciscp => true).count / 1000
    MPackage.where(:is_ciscp => true).find_in_batches.with_index do |group, batch|
      puts "Processing CISCP group ##{batch+1} of #{total_groups+1}"
      group.each do |object|
        badge_names = BadgeStatus.where(:remote_object_id => object.guid).collect(&:badge_name)
        begin
          if badge_names.include?("CISCP")
            BadgeStatus.where(:remote_object_id => object.guid, :badge_name => "CISCP").delete_all
          end
        rescue Exception => e
          puts "Could not transition #{object.id}, skipping Package. Error: #{e.to_s}"
        end
      end
    end

    total_groups = MPackage.where.not(:uploaded_file_id => nil).count / 1000
    MPackage.where.not(:uploaded_file_id => nil).find_in_batches.with_index do |group, batch|
      puts "Processing Uploaded Badge group ##{batch+1} of #{total_groups+1}"
      group.each do |object|
        badge_names = BadgeStatus.where(:remote_object_id => object.guid).collect(&:badge_name)
        begin
          if badge_names.include?("UPLOADED")
            BadgeStatus.where(:remote_object_id => object.guid, :badge_name => "UPLOADED").delete_all
          end
        rescue Exception => e
          puts "Could not transition #{object.id}, skipping Package. Error: #{e.to_s}"
        end
      end
    end

    total_groups = MPackage.where.not(:feeds => nil).count / 1000
    MPackage.where.not(:feeds => nil).find_in_batches.with_index do |group, batch|
      puts "Processing Uploaded Badge group ##{batch+1} of #{total_groups+1}"
      group.each do |object|
        badge_names = BadgeStatus.where(:remote_object_id => object.guid).collect(&:badge_name)
        begin
          package_feeds = object.feeds.split(",")
          package_feeds.each do |x|
            if badge_names.include?(x)
              BadgeStatus.where(:remote_object_id => object.guid, :badge_name => x).delete_all
            end
          end
        rescue Exception => e
          puts "Could not transition #{object.id}, skipping Package. Error: #{e.to_s}"
        end
      end
    end

    ActiveRecord::Base.record_timestamps = true
    ::Sunspot.session = ::Sunspot.session.original_session
  end
end
