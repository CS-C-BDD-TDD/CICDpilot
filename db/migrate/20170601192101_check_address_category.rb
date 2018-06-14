class CheckAddressCategory < ActiveRecord::Migration
  class MAddress < ActiveRecord::Base
    self.table_name = 'cybox_addresses'
  end

  def up

    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

    MAddress.where(:category => nil).find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch}"
      group.each do |add|
        next if add.category.present?

        add_category = ''
        if Address.valid_ipv4_value?(add.address_value_normalized)
          add_category = 'ipv4-addr'
        elsif Address.valid_ipv6_value?(add.address_value_normalized)
          add_category = 'ipv6-addr'
        elsif Address.valid_email_address?(add.address_value_normalized)
          add_category = 'e-mail'
        end

        begin
          if add_category.present?
            add.save!
          else
            add.destroy!
          end
        rescue Exception => e
          puts "Could not transition #{add.id}, skipping category. Error: #{e.to_s}"
          add.category = ""
          add.save
        end
      end
    end

    ::Sunspot.session = ::Sunspot.session.original_session
  end
end
