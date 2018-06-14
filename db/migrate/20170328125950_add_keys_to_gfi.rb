class AddKeysToGfi < ActiveRecord::Migration
	
	class MGfi < ActiveRecord::Base
	 	self.table_name = :gfis
    has_one :address, primary_key: :id, foreign_key: :gfi_id
	  has_one :domain, primary_key: :id, foreign_key: :gfi_id
	  has_one :email_message, primary_key: :id, foreign_key: :gfi_id
	  has_one :cybox_file, primary_key: :id, foreign_key: :gfi_id
	  has_one :dns_record, primary_key: :id, foreign_key: :gfi_id
	end

  def up
  	::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

  	if !ActiveRecord::Base.connection.column_exists?(:gfis, :remote_object_id)
	    add_column :gfis, :remote_object_id, :string
	  end

	  if !ActiveRecord::Base.connection.column_exists?(:gfis, :remote_object_type)
	    add_column :gfis, :remote_object_type, :string
	  end

    MGfi.find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch}"
      group.each do |obj|
      	begin
      		if obj.remote_object_id.blank? || obj.remote_object_type.blank?
		      	if obj.address.present?
		      		obj.remote_object_id = obj.address.cybox_object_id
		      		obj.remote_object_type = obj.address.class.to_s
		      	elsif obj.domain.present?
		      		obj.remote_object_id = obj.domain.cybox_object_id
		      		obj.remote_object_type = obj.domain.class.to_s
		      	elsif obj.email_message.present?
		      		obj.remote_object_id = obj.email_message.cybox_object_id
		      		obj.remote_object_type = obj.email_message.class.to_s
		      	elsif obj.cybox_file.present?
		      		obj.remote_object_id = obj.cybox_file.cybox_object_id
		      		obj.remote_object_type = obj.cybox_file.class.to_s
		      	elsif obj.dns_record.present?
		      		obj.remote_object_id = obj.dns_record.cybox_object_id
		      		obj.remote_object_type = obj.dns_record.class.to_s
		      	else
		      		puts "Unknown remote object for GFI id: #{obj.id}"
		      	end

		      	obj.save!
		      end
	      rescue Exception => e
	      	puts "Could not transition GFI id: #{obj.id}, Exception: #{e.to_s}"
	      end
      end
    end

  	# remove gfi_id foreign keys we will be putting it on the gfi table
  	if ActiveRecord::Base.connection.column_exists?(:cybox_addresses, :gfi_id)
  		rename_column :cybox_addresses, :gfi_id, :gfi_id_old
  	end

  	if ActiveRecord::Base.connection.column_exists?(:cybox_domains, :gfi_id)
    	rename_column :cybox_domains, :gfi_id, :gfi_id_old
  	end

    if ActiveRecord::Base.connection.column_exists?(:cybox_email_messages, :gfi_id)
    	rename_column :cybox_email_messages, :gfi_id, :gfi_id_old
  	end

    if ActiveRecord::Base.connection.column_exists?(:cybox_files, :gfi_id)
    	rename_column :cybox_files, :gfi_id, :gfi_id_old
  	end

    if ActiveRecord::Base.connection.column_exists?(:cybox_dns_records, :gfi_id)
    	rename_column :cybox_dns_records, :gfi_id, :gfi_id_old
  	end

  	# Remove Indexes
  	if ActiveRecord::Base.connection.index_exists?(:cybox_addresses, :gfi_id)
	    remove_index :cybox_addresses, :gfi_id
	  end
    if ActiveRecord::Base.connection.index_exists?(:cybox_domains, :gfi_id)
	    remove_index :cybox_domains, :gfi_id
	  end
    if ActiveRecord::Base.connection.index_exists?(:cybox_email_messages, :gfi_id)
	    remove_index :cybox_email_messages, :gfi_id
	  end
    if ActiveRecord::Base.connection.index_exists?(:cybox_files, :gfi_id)
	    remove_index :cybox_files, :gfi_id
	  end
    if ActiveRecord::Base.connection.index_exists?(:cybox_dns_records, :gfi_id)
	    remove_index :cybox_dns_records, :gfi_id
	  end

	  # Added Indexes
	  if !ActiveRecord::Base.connection.index_exists?(:gfis, :remote_object_id)
	  	add_index :gfis, :remote_object_id
	  end

    ::Sunspot.session = ::Sunspot.session.original_session
  end

  def down
  	::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

  	# set the old id's back on the tables
  	if ActiveRecord::Base.connection.column_exists?(:cybox_addresses, :gfi_id_old)
  		rename_column :cybox_addresses, :gfi_id_old, :gfi_id
  	end

  	if ActiveRecord::Base.connection.column_exists?(:cybox_domains, :gfi_id_old)
    	rename_column :cybox_domains, :gfi_id_old, :gfi_id
  	end

    if ActiveRecord::Base.connection.column_exists?(:cybox_email_messages, :gfi_id_old)
    	rename_column :cybox_email_messages, :gfi_id_old, :gfi_id
  	end

    if ActiveRecord::Base.connection.column_exists?(:cybox_files, :gfi_id_old)
    	rename_column :cybox_files, :gfi_id_old, :gfi_id
  	end

    if ActiveRecord::Base.connection.column_exists?(:cybox_dns_records, :gfi_id_old)
    	rename_column :cybox_dns_records, :gfi_id_old, :gfi_id
  	end

  	# remove remote_object_id polymorphic foreign keys
  	if ActiveRecord::Base.connection.column_exists?(:gfis, :remote_object_id)
	    remove_column :gfis, :remote_object_id, :string
	  end

	  if ActiveRecord::Base.connection.column_exists?(:gfis, :remote_object_type)
	    remove_column :gfis, :remote_object_type, :string
	  end

  	# add Indexes
  	if !ActiveRecord::Base.connection.index_exists?(:cybox_addresses, :gfi_id)
	    add_index :cybox_addresses, :gfi_id
	  end
    if !ActiveRecord::Base.connection.index_exists?(:cybox_domains, :gfi_id)
	    add_index :cybox_domains, :gfi_id
	  end
    if !ActiveRecord::Base.connection.index_exists?(:cybox_email_messages, :gfi_id)
	    add_index :cybox_email_messages, :gfi_id
	  end
    if !ActiveRecord::Base.connection.index_exists?(:cybox_files, :gfi_id)
	    add_index :cybox_files, :gfi_id
	  end
    if !ActiveRecord::Base.connection.index_exists?(:cybox_dns_records, :gfi_id)
	    add_index :cybox_dns_records, :gfi_id
	  end

	  # remove Indexes
	  if ActiveRecord::Base.connection.index_exists?(:gfis, :remote_object_id)
	  	remove_index :gfis, :remote_object_id
	  end

    ::Sunspot.session = ::Sunspot.session.original_session
  end
end
