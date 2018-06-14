namespace :cybox_hashes do
  task :fix => :environment do
  	
		# Call set_cybox_hash on all CYBOX objects with nil cybox_hash
		if Object.const_get(:DnsRecord).is_a?(Class)
			@records = DnsRecord.where(cybox_hash: nil)
			@records.each do |o|
				o.set_cybox_hash
				o.save
			end
		end

		if Object.const_get(:Domain).is_a?(Class)
			@domains = Domain.where(cybox_hash: nil)
			@domains.each do |o|
				o.set_cybox_hash
				o.save
			end
		end

		if Object.const_get(:EmailMessage).is_a?(Class)
			@emails = EmailMessage.where(cybox_hash: nil)
			@emails.each do |o|
				o.set_cybox_hash
				o.save
			end
		end

		if Object.const_get(:HttpSession).is_a?(Class)
			@sessions = HttpSession.where(cybox_hash: nil)
			@sessions.each do |o|
				o.set_cybox_hash
				o.save
			end
		end

		if Object.const_get(:Address).is_a?(Class)
			@addresses = Address.where(cybox_hash: nil)
			@addresses.each do |o|
				o.set_cybox_hash
				o.save
			end
		end

		if Object.const_get(:CyboxMutex).is_a?(Class)
			@mutexes = CyboxMutex.where(cybox_hash: nil)
			@mutexes.each do |o|
				o.set_cybox_hash
				o.save
			end
		end

		if Object.const_get(:NetworkConnection).is_a?(Class)
			@connections = NetworkConnection.where(cybox_hash: nil)
			@connections.each do |o|
				o.set_cybox_hash
				o.save
			end
		end

		if Object.const_get(:Registry).is_a?(Class)
			@registries = Registry.where(cybox_hash: nil)
			@registries.each do |o|
				o.set_cybox_hash
				o.save
			end
		end

		if Object.const_get(:RegistryValue).is_a?(Class)
			@values = RegistryValue.where(cybox_hash: nil)
			@values.each do |o|
				o.set_cybox_hash
				o.save
			end
		end

		if Object.const_get(:Uri).is_a?(Class)
			@uris = Uri.where(cybox_hash: nil)
			@uris.each do |o|
				o.set_cybox_hash
				o.save
			end
		end

  end
end