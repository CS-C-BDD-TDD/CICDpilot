class WeatherMapStatsController < ApplicationController
  
  # Get DBMS-specific date-conversion function (TRUNC for Oracle or DATE
  # otherwise).
  def sql_date_func(func_arg)
    func_arg = func_arg.present? ? "(#{func_arg.to_s})" : ''
    ActiveRecord::Base.connection.instance_values['config'][:adapter] ==
        'oracle_enhanced' ? "TRUNC#{func_arg}" : "DATE#{func_arg}"
  end

  # Get total count of indicators created from weather map depending on
  # the type.
  def weather_map_ind_total_count(type)
    Indicator.joins(type).count
  end

  # Get count of indicators created from weather map data depending on 
  # the type within a
  # date range.
  def weather_map_ind_range_count(type, start_date, end_date)
    Indicator.joins(type).where(created_at: start_date..end_date)
        .count
  end

  # Get counts of weather map depending on the type 
  # loaded grouped by date within a
  # date range.
  def weather_map_loads_by_day(type, start_date, end_date)
    type.unscoped.where(created_at: start_date..end_date)
        .where.not(combined_score: nil)
        .group(sql_date_func('created_at'))
        .count
  end

  # Get count of indicators created from weather map 
  # depending on the type within canned
  # date ranges and the total count.
  def weather_map_ind_counts(type, today_date)
    {
        :total_count => weather_map_ind_total_count(type),
        :yesterday_count => weather_map_ind_range_count(
          type,
          today_date.days_ago(1).beginning_of_day,
          today_date.days_ago(1).end_of_day),
        :today_count => weather_map_ind_range_count(
          type,
          today_date.beginning_of_day,
          today_date.end_of_day),
        :last_7_days_count => weather_map_ind_range_count(
          type,
          today_date.days_ago(6).beginning_of_day,
          today_date.end_of_day),
        :last_30_days_count => weather_map_ind_range_count(
          type,
          today_date.days_ago(29).beginning_of_day,
          today_date.end_of_day),
        :custom_range_count => (params[:ebt].present? &&
          params[:iet].present?) ? weather_map_ind_range_count(
          type,
          params[:ebt].beginning_of_day,
          params[:iet].end_of_day) : nil
    }
  end

  # Get counts of weather map depending on the type
  # loaded grouped by date within the
  # past num_days number of days.
  def weather_map_loads_num_days(type, today_date, num_days)
    start_date = today_date.days_ago(num_days - 1).beginning_of_day
    end_date = today_date.end_of_day
    loads_hash = weather_map_loads_by_day(type ,start_date, end_date)
    loads_hash.keys.each { |date|
      loads_hash[date.to_date.strftime('%Y-%m-%d')] =
          loads_hash.delete(date)
    }
    loads_array = []
    date = start_date
    while date < end_date
      fmt_date = date.strftime('%Y-%m-%d')
      loads_array << {
          :date => fmt_date,
          :count => loads_hash[fmt_date].present? ? loads_hash[fmt_date] : 0
      }
      date += 1.day
    end
    loads_array
  end

  # Build the wmdstats hash containing the stats and render it as JSON.
  def build_addresses
    today_date = Date.today
    @wmdstats = {
        :counts => weather_map_ind_counts(:weather_map_addresses, today_date),
        :loads => weather_map_loads_num_days(Address, today_date, 10)
    }
    respond_to do |format|
      format.any(:json, :html) { render json: @wmdstats }
    end
  end

  # Build the wmdstats hash for domains containing the stats and render it as JSON.
  def build_domains
    today_date = Date.today
    @wmdstats = {
        :counts => weather_map_ind_counts(:weather_map_domains, today_date),
        :loads => weather_map_loads_num_days(Domain, today_date, 10)
    }
    respond_to do |format|
      format.any(:json, :html) { render json: @wmdstats }
    end
  end
end
