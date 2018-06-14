class AisStatisticsController < ApplicationController
  
  def index
    @ais_statistics =
        AisStatistic.where('stix_package_stix_id in (?) OR stix_package_original_id in (?) OR guid in (?)',
                           params[:ids], params[:ids], params[:ids]) if params[:ids]
    limit = record_limit(params[:amount].to_i)
    offset = params[:offset] || 0

    if params[:sanitized_q].present? || params[:original_q].present? || params[:received_time_ebt].present? || params[:received_time_iet].present? || params[:indicator_amount_q].present? || params[:flare_in_status_q].present? || params[:ciap_status_q].present? || params[:ecis_status_q].present? || params[:flare_out_status_q].present? || params[:feeds_q].present? || params[:disseminated_time_ebt].present? || params[:disseminated_time_iet].present? || params[:hr_count_q].present? || params[:ecis_hr_status_q].present? || params[:flare_out_hr_status_q].present? || params[:disseminated_time_hr_ebt].present? || params[:disseminated_time_hr_iet].present?
      search = Search.ais_statistic_search({
        column: params[:column],
        direction: params[:direction],
        received_time_ebt: params[:received_time_ebt],
        received_time_iet: params[:received_time_iet],
        disseminated_time_ebt: params[:disseminated_time_ebt],
        disseminated_time_iet: params[:disseminated_time_iet],
        disseminated_time_hr_ebt: params[:disseminated_time_hr_ebt],
        disseminated_time_hr_iet: params[:disseminated_time_hr_iet],
        limit: (limit || Sunspot.config.pagination.default_per_page),
        offset: offset,
        sanitized_q: params[:sanitized_q],
        original_q: params[:original_q],
        indicator_amount_q: params[:indicator_amount_q].present? ? params[:indicator_amount_q].to_i : nil,
        flare_in_status_q: params[:flare_in_status_q].present? ? params[:flare_in_status_q].to_bool : nil,
        ciap_status_q: params[:ciap_status_q].present? ? params[:ciap_status_q].to_bool : nil,
        ecis_status_q: params[:ecis_status_q].present? ? params[:ecis_status_q].to_bool : nil,
        flare_out_status_q: params[:flare_out_status_q].present? ? params[:flare_out_status_q].to_bool : nil,
        feeds_q: params[:feeds_q],
        hr_count_q: params[:hr_count_q],
        ecis_hr_status_q: params[:ecis_hr_status_q].present? ? params[:ecis_hr_status_q].to_bool : nil,
        flare_out_hr_status_q: params[:flare_out_hr_status_q].present? ? params[:flare_out_hr_status_q].to_bool : nil
      })
      total_count = search.total
      @ais_statistics = search.results

      @ais_statistics ||= []
    else
      @ais_statistics ||= AisStatistic.all.reorder(received_time: :desc)

      @ais_statistics = apply_sort(@ais_statistics, params)
      @ais_statistics = @ais_statistics.includes(:human_review)

      total_count = @ais_statistics.count
      @ais_statistics = @ais_statistics.limit(limit).offset(offset)
    end
    @metadata = Metadata.new
    @metadata.total_count = total_count

    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, ais_statistics: @ais_statistics} }
    end
  end

  def show
    @ais_statistic =
        AisStatistic.includes(:system_logs).where('stix_package_stix_id = ? OR stix_package_original_id = ? OR guid = ?',
            params[:id], params[:id], params[:id]).first

    if @ais_statistic
      render json: @ais_statistic
    else
      render json: {errors: "Invalid AIS Statistic record number"}, status: 400
    end
  end

  def create
    begin
      @ais_statistics, @system_logs =
          AisStatistic.custom_save_or_update(ais_statistic_params)
      ais_stats_with_errors =
          AisStatistic.validate_ais_statistics(@ais_statistics, true)
      system_logs_with_errors =
          Logging::SystemLog.validate_system_logs(@system_logs, false)
    rescue Exception => e
      render json: {errors: e.message.to_s}, status: :unprocessable_entity
      return
    end
    if @ais_statistics.present?
      if ais_stats_with_errors.empty? && system_logs_with_errors.empty?
        render json: @ais_statistics
        # We only need to replicate on ECIS to ciap
        ReplicationUtilities.replicate_ais_statistics(@ais_statistics, 'ais_statistic_forward') if AppUtilities.is_ecis?
      else
        render json: {
            errors: ais_stats_with_errors.collect(&:errors) |
                system_logs_with_errors.collect(&:errors)
        }, status: :unprocessable_entity
      end
    else
      render json: {
          errors: ['Empty POST request received without one or more AIS Statistics.']
      }, status: :unprocessable_entity
    end
  end

  def update
    begin
      @ais_statistics, @system_logs =
          AisStatistic.custom_save_or_update(ais_statistic_params)
      ais_stats_with_errors =
          AisStatistic.validate_ais_statistics(@ais_statistics, true)
      system_logs_with_errors =
          Logging::SystemLog.validate_system_logs(@system_logs, false)
    rescue Exception => e
      render json: {errors: e.message.to_s}, status: :unprocessable_entity
      return
    end
    if @ais_statistics.present?
      if ais_stats_with_errors.empty? && system_logs_with_errors.empty?
        render json: @ais_statistics
        # We only need to replicate on ECIS to ciap
        ReplicationUtilities.replicate_ais_statistics(@ais_statistics, 'ais_statistic_forward') if AppUtilities.is_ecis?
      else
        render json: {
            errors: ais_stats_with_errors.collect(&:errors) |
                system_logs_with_errors.collect(&:errors)
        }, status: :unprocessable_entity
      end
    else
      render json: {
          errors: ['Empty POST request received without one or more AIS Statistics.']
      }, status: :unprocessable_entity
    end
  end

  def destroy
  end

  def loads_num_days(start_date, end_date, field)
    loads_hash = {}
    AisStatistic.where((field.to_sym) => start_date..end_date).group_by do |x| x[(field.to_sym)].strftime("%Y-%m-%d") end.each do |day, records| loads_hash[day] = records.count end

    AisStatistic.where(:dissemination_time_hr => start_date..end_date).group_by do |x| x[:dissemination_time_hr].strftime("%Y-%m-%d") end.each do |day, records| loads_hash[day] = loads_hash[day].present? ? (loads_hash[day] + records.count) : records.count end

    ind_hash = {}
    AisStatistic.where((field.to_sym) => start_date..end_date).group_by{|x| x[(field.to_sym)].strftime("%Y-%m-%d")}.each do |day, records| ind_hash[day] = records.map do |x| x[:indicator_amount] end.compact.sum end

    AisStatistic.where(:dissemination_time_hr => start_date..end_date).group_by{|x| x[:dissemination_time_hr].strftime("%Y-%m-%d")}.each do |day, records| ind_hash[day] = ind_hash[day].present? ? (ind_hash[day] + (records.map do |x| x[:indicator_amount] end.compact.sum)) : records.map do |x| x[:indicator_amount] end.compact.sum end

    hr_hash = {}
    HumanReview.where(:created_at => start_date..end_date).group_by{|x| x.created_at.strftime("%Y-%m-%d")}.each do |day, records| hr_hash[day] = records.count end

    hr_pending_hash = {}
    HumanReview.where(:created_at => start_date..end_date, :decided_at => nil).group_by{|x| x.created_at.strftime("%Y-%m-%d")}.each do |day, records| hr_pending_hash[day] = records.count end

    hr_decided_hash = {}
    HumanReview.where(:decided_at => start_date..end_date).group_by{|x| x.decided_at.strftime("%Y-%m-%d")}.each do |day, records| hr_decided_hash[day] = records.count end

    loads_array = []
    date = start_date
    while date < end_date
      fmt_date = date.strftime('%Y-%m-%d')
      loads_array << {
          :date => fmt_date,
          :count => loads_hash[fmt_date].present? ? loads_hash[fmt_date] : 0,
          :indicator_amount => ind_hash[fmt_date].present? ? ind_hash[fmt_date] : 0,
          :hr_amount => hr_hash[fmt_date].present? ? hr_hash[fmt_date] : 0,
          :hr_pending_amount => hr_pending_hash[fmt_date].present? ? hr_pending_hash[fmt_date] : 0,
          :hr_decided_amount => hr_decided_hash[fmt_date].present? ? hr_decided_hash[fmt_date] : 0
      }
      date += 1.day
    end
    loads_array
  end

  def loads_tlp_counts(start_date, end_date, field)
    green_hash = {}
    AisStatistic.where((field.to_sym) => start_date..end_date).joins(:stix_package => {:stix_markings => :tlp_marking_structure}).where(tlp_structures: {color: "green"}).group_by do |x| x[(field.to_sym)].strftime("%Y-%m-%d") end.each do |day, records| green_hash[day] = records.count end
    AisStatistic.where(:dissemination_time_hr => start_date..end_date).joins(:stix_package => {:stix_markings => :tlp_marking_structure}).where(tlp_structures: {color: "green"}).group_by do |x| x[:dissemination_time_hr].strftime("%Y-%m-%d") end.each do |day, records| green_hash[day] = green_hash[day].present? ? (green_hash[day] + records.count) : records.count end

    AisStatistic.where((field.to_sym) => start_date..end_date).joins(:stix_package => {:stix_markings => :ais_consent_marking_structure}).where(ais_consent_marking_structures: {color: "green"}).group_by do |x| x[(field.to_sym)].strftime("%Y-%m-%d") end.each do |day, records| green_hash[day] = records.count end
    AisStatistic.where(:dissemination_time_hr => start_date..end_date).joins(:stix_package => {:stix_markings => :ais_consent_marking_structure}).where(ais_consent_marking_structures: {color: "green"}).group_by do |x| x[:dissemination_time_hr].strftime("%Y-%m-%d") end.each do |day, records| green_hash[day] = green_hash[day].present? ? (green_hash[day] + records.count) : records.count end

    amber_hash = {}
    AisStatistic.where((field.to_sym) => start_date..end_date).joins(:stix_package => {:stix_markings => :tlp_marking_structure}).where(tlp_structures: {color: "amber"}).group_by do |x| x[(field.to_sym)].strftime("%Y-%m-%d") end.each do |day, records| amber_hash[day] = records.count end
    AisStatistic.where(:dissemination_time_hr => start_date..end_date).joins(:stix_package => {:stix_markings => :tlp_marking_structure}).where(tlp_structures: {color: "amber"}).group_by do |x| x[:dissemination_time_hr].strftime("%Y-%m-%d") end.each do |day, records| amber_hash[day] = amber_hash[day].present? ? (amber_hash[day] + records.count) : records.count end

    AisStatistic.where((field.to_sym) => start_date..end_date).joins(:stix_package => {:stix_markings => :ais_consent_marking_structure}).where(ais_consent_marking_structures: {color: "amber"}).group_by do |x| x[(field.to_sym)].strftime("%Y-%m-%d") end.each do |day, records| amber_hash[day] = records.count end
    AisStatistic.where(:dissemination_time_hr => start_date..end_date).joins(:stix_package => {:stix_markings => :ais_consent_marking_structure}).where(ais_consent_marking_structures: {color: "amber"}).group_by do |x| x[:dissemination_time_hr].strftime("%Y-%m-%d") end.each do |day, records| amber_hash[day] = amber_hash[day].present? ? (amber_hash[day] + records.count) : records.count end

    white_hash = {}
    AisStatistic.where((field.to_sym) => start_date..end_date).joins(:stix_package => {:stix_markings => :tlp_marking_structure}).where(tlp_structures: {color: "white"}).group_by do |x| x[(field.to_sym)].strftime("%Y-%m-%d") end.each do |day, records| white_hash[day] = records.count end
    AisStatistic.where(:dissemination_time_hr => start_date..end_date).joins(:stix_package => {:stix_markings => :tlp_marking_structure}).where(tlp_structures: {color: "white"}).group_by do |x| x[:dissemination_time_hr].strftime("%Y-%m-%d") end.each do |day, records| white_hash[day] = white_hash[day].present? ? (white_hash[day] + records.count) : records.count end

    AisStatistic.where((field.to_sym) => start_date..end_date).joins(:stix_package => {:stix_markings => :ais_consent_marking_structure}).where(ais_consent_marking_structures: {color: "white"}).group_by do |x| x[(field.to_sym)].strftime("%Y-%m-%d") end.each do |day, records| white_hash[day] = records.count end
    AisStatistic.where(:dissemination_time_hr => start_date..end_date).joins(:stix_package => {:stix_markings => :ais_consent_marking_structure}).where(ais_consent_marking_structures: {color: "white"}).group_by do |x| x[:dissemination_time_hr].strftime("%Y-%m-%d") end.each do |day, records| white_hash[day] = white_hash[day].present? ? (white_hash[day] + records.count) : records.count end

    loads_array = []
    date = start_date
    while date < end_date
      fmt_date = date.strftime('%Y-%m-%d')
      loads_array << {
          :date => fmt_date,
          :green_count => green_hash[fmt_date].present? ? green_hash[fmt_date] : 0,
          :amber_count => amber_hash[fmt_date].present? ? amber_hash[fmt_date] : 0,
          :white_count => white_hash[fmt_date].present? ? white_hash[fmt_date] : 0
      }
      date += 1.day
    end
    
    loads_array
  end

  def loads_user_counts(start_date, end_date, field, user)
    users_hash = {}
    AisStatistic.where((field.to_sym) => start_date..end_date).joins(:uploaded_file => :user).where(users: {username: user}).group_by do |x| x[(field.to_sym)].strftime("%Y-%m-%d") end.each do |day, records| users_hash[day] = records.count end
    AisStatistic.where(:dissemination_time_hr => start_date..end_date).joins(:uploaded_file => :user).where(users: {username: user}).group_by do |x| x[:dissemination_time_hr].strftime("%Y-%m-%d") end.each do |day, records| users_hash[day] = users_hash[day].present? ? (users_hash[day] + records.count) : records.count end

    ind_hash = {}
    AisStatistic.where((field.to_sym) => start_date..end_date).joins(:uploaded_file => :user).where(users: {username: user}).group_by{|x| x[(field.to_sym)].strftime("%Y-%m-%d")}.each do |day, records| ind_hash[day] = records.map do |x| x[:indicator_amount] end.compact.sum end
    AisStatistic.where(:dissemination_time_hr => start_date..end_date).joins(:uploaded_file => :user).where(users: {username: user}).group_by{|x| x[:dissemination_time_hr].strftime("%Y-%m-%d")}.each do |day, records| ind_hash[day] = ind_hash[day].present? ? (ind_hash[day] + records.map do |x| x[:indicator_amount] end.compact.sum) : records.map do |x| x[:indicator_amount] end.compact.sum end

    hr_hash = {}
    HumanReview.where(:created_at => start_date..end_date).joins(:uploaded_file => :user).where(users: {username: user}).group_by{|x| x.created_at.strftime("%Y-%m-%d")}.each do |day, records| hr_hash[day] = records.count end

    hr_decided_hash = {}
    HumanReview.where(:decided_at => start_date..end_date).joins(:decided_by).where(users: {username: user}).group_by{|x| x.decided_at.strftime("%Y-%m-%d")}.each do |day, records| hr_decided_hash[day] = records.count end

    loads_array = []
    date = start_date
    while date < end_date
      fmt_date = date.strftime('%Y-%m-%d')
      loads_array << {
          :date => fmt_date,
          :count => users_hash[fmt_date].present? ? users_hash[fmt_date] : 0,
          :indicator_amount => ind_hash[fmt_date].present? ? ind_hash[fmt_date] : 0,
          :hr_amount => hr_hash[fmt_date].present? ? hr_hash[fmt_date] : 0,
          :hr_decided_amount => hr_decided_hash[fmt_date].present? ? hr_decided_hash[fmt_date] : 0
      }
      date += 1.day
    end
    loads_array
  end

  def loads_feed_counts(start_date, end_date, field)
    ais_hash = {}
    AisStatistic.where((field.to_sym) => start_date..end_date).where("ais_statistics.feeds like ?", "%AIS%").group_by do |x| x[(field.to_sym)].strftime("%Y-%m-%d") end.each do |day, records| ais_hash[day] = records.count end
    AisStatistic.where(:dissemination_time_hr => start_date..end_date).where("ais_statistics.feeds like ?", "%AIS%").group_by do |x| x[:dissemination_time_hr].strftime("%Y-%m-%d") end.each do |day, records| ais_hash[day] = ais_hash[day].present? ? (ais_hash[day] + records.count) : records.count end

    fedgov_hash = {}
    AisStatistic.where((field.to_sym) => start_date..end_date).where("ais_statistics.feeds like ?", "%FEDGOV%").group_by do |x| x[(field.to_sym)].strftime("%Y-%m-%d") end.each do |day, records| fedgov_hash[day] = records.count end
    AisStatistic.where(:dissemination_time_hr => start_date..end_date).where("ais_statistics.feeds like ?", "%FEDGOV%").group_by do |x| x[:dissemination_time_hr].strftime("%Y-%m-%d") end.each do |day, records| fedgov_hash[day] = fedgov_hash[day].present? ? (fedgov_hash[day] + records.count) : records.count end

    ciscp_hash = {}
    AisStatistic.where((field.to_sym) => start_date..end_date).where("ais_statistics.feeds like ?", "%CISCP%").group_by do |x| x[(field.to_sym)].strftime("%Y-%m-%d") end.each do |day, records| ciscp_hash[day] = records.count end
    AisStatistic.where(:dissemination_time_hr => start_date..end_date).where("ais_statistics.feeds like ?", "%CISCP%").group_by do |x| x[:dissemination_time_hr].strftime("%Y-%m-%d") end.each do |day, records| ciscp_hash[day] = ciscp_hash[day].present? ? (ciscp_hash[day] + records.count) : records.count end

    loads_array = []
    date = start_date
    while date < end_date
      fmt_date = date.strftime('%Y-%m-%d')
      loads_array << {
          :date => fmt_date,
          :ais_count => ais_hash[fmt_date].present? ? ais_hash[fmt_date] : 0,
          :fedgov_count => fedgov_hash[fmt_date].present? ? fedgov_hash[fmt_date] : 0,
          :ciscp_count => ciscp_hash[fmt_date].present? ? ciscp_hash[fmt_date] : 0
      }
      date += 1.day
    end
    loads_array
  end

  def loads_hr_queue(start_date, end_date)
    {
      :one_week => HumanReview.where.not(status: ['R', 'A']).where("created_at >= ?", 1.weeks.ago).count,
      :two_weeks => HumanReview.where.not(status: ['R', 'A']).where("created_at >= ? AND created_at < ?", 2.weeks.ago, 1.weeks.ago).count,
      :one_month => HumanReview.where.not(status: ['R', 'A']).where("created_at >= ? AND created_at < ?", 1.months.ago, 2.weeks.ago).count,
      :three_months => HumanReview.where.not(status: ['R', 'A']).where("created_at >= ? AND created_at < ?", 3.months.ago, 1.months.ago).count,
      :six_months => HumanReview.where.not(status: ['R', 'A']).where("created_at >= ? AND created_at < ?", 6.months.ago, 3.months.ago).count,
      :over_six_months => HumanReview.where.not(status: ['R', 'A']).where("created_at < ?", 6.months.ago).count,
      :total => HumanReview.where.not(status: ['R', 'A']).count
    }
  end

  # date ranges and the total count.
  def build_counts(today_date, field)
    total_count = AisStatistic.where.not((field.to_sym) => nil).count
    total_count += AisStatistic.where.not(:dissemination_time_hr => nil).count

    yesterday_count = AisStatistic.where((field.to_sym) => today_date.days_ago(1).beginning_of_day..today_date.days_ago(1).end_of_day).count
    yesterday_count += AisStatistic.where(:dissemination_time_hr => today_date.days_ago(1).beginning_of_day..today_date.days_ago(1).end_of_day).count

    today_count = AisStatistic.where((field.to_sym) => today_date.beginning_of_day..today_date.end_of_day).count
    today_count += AisStatistic.where(:dissemination_time_hr => today_date.beginning_of_day..today_date.end_of_day).count

    last_7_days_count = AisStatistic.where((field.to_sym) => today_date.days_ago(6).beginning_of_day..today_date.end_of_day).count
    last_7_days_count += AisStatistic.where(:dissemination_time_hr => today_date.days_ago(6).beginning_of_day..today_date.end_of_day).count

    last_30_days_count = AisStatistic.where((field.to_sym) => today_date.days_ago(29).beginning_of_day..today_date.end_of_day).count
    last_30_days_count += AisStatistic.where(:dissemination_time_hr => today_date.days_ago(29).beginning_of_day..today_date.end_of_day).count

    custom_range_count = 0
    if params[:ebt].present? && params[:iet].present?
      custom_range_count = AisStatistic.where((field.to_sym) => params[:ebt].beginning_of_day..params[:iet].end_of_day).count
      custom_range_count += AisStatistic.where(:dissemination_time_hr => params[:ebt].beginning_of_day..params[:iet].end_of_day).count
    end

    {
      :total_count => total_count,
      :yesterday_count => yesterday_count,
      :today_count => today_count,
      :last_7_days_count => last_7_days_count,
      :last_30_days_count => last_30_days_count,
      :custom_range_count => custom_range_count
    }
  end

  def build_metrics
    today_date = Date.today

    start_date = params[:ebt].present? ? params[:ebt].beginning_of_day : today_date.days_ago(9).beginning_of_day
    end_date = params[:iet].present? ? params[:iet].end_of_day : today_date.end_of_day
    field = params[:field].present? ? params[:field] : 'received_time'
    user = params[:user].present? ? params[:user] : ''

    @metrics = {
      :counts => build_counts(today_date, field),
      :loads => loads_num_days(start_date, end_date, field),
      :tlp_loads => loads_tlp_counts(start_date, end_date, field),
      :user_loads => loads_user_counts(start_date, end_date, field, user),
      :hr_queue_loads => loads_hr_queue(start_date, end_date),
      :feed_loads => loads_feed_counts(start_date, end_date, field)
    }
    respond_to do |format|
      format.any(:json, :html) { render json: @metrics }
    end
  end

private

  def ais_statistic_params
    params.permit(ais_statistic: [
        :guid,
        :stix_package_stix_id,
        :stix_package_original_id,
        :dissemination_time,
        :dissemination_time_hr,
        :received_time,
        :feeds,
        :messages,
        :ais_uid,
        :indicator_amount,
        :flare_in_status,
        :ciap_status,
        :ecis_status,
        :flare_out_status,
        :ecis_status_hr,
        :flare_out_status_hr,
        :system_logs => [:stix_package_id, :sanitized_package_id,
                         :timestamp, :source, :log_level, :message,
                         :text]
    ])
  end
end
