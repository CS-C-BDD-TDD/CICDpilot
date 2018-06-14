namespace :ais_dashboard do
  task :seed => :environment do
    def rand_time(from, to=Time.now)
      Time.at(rand_in_range(from.to_f, to.to_f))
    end

    def rand_in_range(from, to)
      rand * (to - from) + from
    end

    (0..100).each do |x|
      p = StixPackage.create(:title => "#{RandomWord.nouns.next} #{x}",
                             :username => User.first.username)

      a = AisStatistic.new
      a.stix_package = p
      a.stix_package_original_id = "#{RandomWord.nouns.next}:#{RandomWord.adjs.next}-#{x}"
      a.dissemination_time = rand_time(2.years.ago, 1.month.ago)
      a.received_time = rand_time(3.years.ago, 2.years.ago)
      a.feeds = "AIS, FEDGOV"

      (0..rand(10)).each do |i|
        l = Logging::SystemLog.create(:stix_package_id => a.stix_package_original_id, :sanitized_package_id => a.stix_package.stix_id, :timestamp => a.dissemination_time, :source => "#{RandomWord.nouns.next}", :log_level => rand(200..500), :message => "[#{RandomWord.nouns.next}][#{i}] #{RandomWord.nouns.next}")
      end

      a.flare_in_status = true
      a.ciap_status = [true, false].sample
      a.ecis_status = [true, false].sample if a.ciap_status == true
      a.flare_out_status = [true, false].sample if a.ecis_status == true

      if a.flare_out_status == true
        a.ecis_status_hr = [true, false, nil].sample
        u = UploadedFile.create(:file_name => "#{RandomWord.nouns.next}.#{RandomWord.adjs.next}", :user => User.first)
        h = HumanReview.new
        h.uploaded_file = u
        if a.ecis_status_hr == nil
          h.human_review_fields_count = rand(11..20)
          h.comp_human_review_fields_count = rand(0..10)
          if h.comp_human_review_fields_count == 0
            h.status = "N"
          else
            h.status = "I"
          end
        else
          h.human_review_fields_count = rand(11..20)
          h.comp_human_review_fields_count = h.human_review_fields_count
          h.status = "A"
          h.decided_at = Time.now
        end

        a.uploaded_file_id = u.id
      end

      a.flare_out_status_hr = [true, false].sample if a.ecis_status_hr == true

      a.dissemination_time_hr = rand_time(1.month.ago, 1.day.ago) if a.flare_out_status_hr == true

      if h.present? && u.present?
        u.save!
        h.save!
      end

      a.indicator_amount = rand(100)
      a.save!
    end
  end

  task :delete => :environment do
    HumanReview.destroy_all
    UploadedFile.destroy_all
    AisStatistic.destroy_all
  end
end
