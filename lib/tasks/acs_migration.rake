require 'stix'

task :acs_migration, [:start, :batch_size] => :environment do |t, args|
  start = args.start || 0
  batch_size = args.batch_size || 1000
  IsaAssertionStructure.find_in_batches(start: start, batch_size: batch_size).with_index do |group,batch|
    puts "Processing ISA Marking batch #{batch+1}, from #{start+(batch*batch_size)+1} to #{start+(batch*batch_size)+batch_size}"
    group.each_with_index do |assertion,index|
      priv = assertion.isa_privs.select {|p| p.action == 'CISAUSES'}.first
      priv ||= IsaPriv.new(action: 'CISAUSES', effect: 'deny')

      temp = []
      assertion.cs_shargrp.gsub(' ','').split(',').each do |token|
        case token
          when 'CDC','CIKR','DIB','FIN','ISAC'
            if assertion.cs_orgs.blank?
              assertion.cs_orgs = token
            else
              assertion.cs_orgs += ', ' + token
            end
          when 'ICM','ICP'
            temp << 'IC'
          else
            temp << token
        end
      end if assertion.cs_shargrp.present?

      assertion.cs_shargrp = temp.join(', ')

      temp = []
      assertion.cs_info_caveat.gsub(' ','').split(',').each {|token| token == 'FISO' ? temp << 'FISA' : temp << token } if assertion.cs_info_caveat.present?

      temp = []
      assertion.cs_cui.gsub(' ','').split(',').each do |token|
        case token
          when 'FOUO'
            if assertion.cs_formal_determination.blank?
              assertion.cs_formal_determination = 'FOUO'
            else
              assertion.cs_formal_determination << ', FOUO'
            end
          when 'PROPIN'
            temp << 'PR'
          when 'ISVI'
            next
          else
            temp << token
        end
      end if assertion.cs_cui.present?

      assertion.cs_cui = temp.join(', ')

      assertion.further_sharings.each do |fs|
        if fs.scope == 'SECTORONLY'
          begin
            fs.scope = 'SECTOR'
            fs.save!
          rescue Exception => e
            puts "Error saving Further Sharing, id: #{fs.id}"
            puts "#{e.message}"
            puts "Failed at record number #{index} in batch #{batch}"
            fail
          end
        elsif !fs.valid?
          fs.destroy
        end
      end

      if priv.new_record?
        begin
          assertion.isa_privs << priv
        rescue Exception => e
          puts "Error saving ISA Privilege to ISA Assertion #{assertion.id}"
          puts "#{e.message}"
          puts "Failed at record number #{index} in batch #{batch}"
          fail
        end
      end

      begin
        assertion.save!
      rescue Exception => e
        puts "Error saving ISA Assertion #{assertion.id}"
        puts "#{e.message}"
        puts "Failed at record number #{index} in batch #{batch}"
        fail
      end
    end
  end
end
