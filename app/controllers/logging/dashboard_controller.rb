class Logging::DashboardController < ApplicationController

  class AL < ActiveRecord::Base
    self.table_name="authentication_logs"
  end

  #search by dates
  def report

    search_logs = {}
    logins = {}
    indicators_created={}
    manual_uploads={}
    packages_created={}
    api_calls={}
    if params[:start_date].present? && params[:end_date].present?
      group_by=ActiveRecord::Base.connection.instance_values["config"][:adapter]=='sqlite3'?'DATE':'TRUNC'

      s = Date.parse(params[:start_date])
      e = Date.parse(params[:end_date])

      start_date = s.beginning_of_day
      end_date = e.end_of_day

      # Gather number of logins
      if Setting.SSO_AD == true
        login_counts=AL.where(created_at: start_date..end_date).where(access_mode: 'active_directory').order("#{group_by}(created_at) DESC").group("#{group_by}(created_at)").count.to_a
      else
        login_counts=AL.where(created_at: start_date..end_date).where(access_mode: 'basic').order("#{group_by}(created_at) DESC").group("#{group_by}(created_at)").count.to_a
      end
      api_counts=AL.where(created_at: start_date..end_date).where(access_mode: 'api').order("#{group_by}(created_at) DESC").group("#{group_by}(created_at)").count.to_a
      (s..e).each do |date|
        ad=api=0
        if Hash[login_counts][date.beginning_of_day]
          ad=Hash[login_counts][date.beginning_of_day]
        end
        if Hash[api_counts][date.beginning_of_day]
          api=Hash[api_counts][date.beginning_of_day]
        end
        logins[date.to_s[0..9]]=[ad,api]
      end

      # Gather number of Indicators created - broken out by NPE and PE, as well as via upload or UI
      pe_counts=Indicator.where(created_at: start_date..end_date).joins(:created_by_user).where(users: {machine: false}).order("#{group_by}(stix_indicators.created_at) DESC").group("#{group_by}(stix_indicators.created_at)").count.to_a
      npe_counts=Indicator.where(created_at: start_date..end_date).joins(:created_by_user).where(users: {machine: true}).order("#{group_by}(stix_indicators.created_at) DESC").group("#{group_by}(stix_indicators.created_at)").count.to_a
      upload_counts=Indicator.where(created_at: start_date..end_date).joins(:created_by_user).where(users: {machine: false}).joins(stix_packages: :uploaded_file).order("#{group_by}(stix_indicators.created_at) DESC").group("#{group_by}(stix_indicators.created_at)").uniq.count.to_a
      #UI - subtract manual uploaded indicator count from total PE indicator count
      (s..e).each do |date|
        pe=npe=upload=ui=0
        if Hash[pe_counts][date.beginning_of_day]
          pe=Hash[pe_counts][date.beginning_of_day]
        end
        if Hash[npe_counts][date.beginning_of_day]
          npe=Hash[npe_counts][date.beginning_of_day]
        end
        if Hash[upload_counts][date.beginning_of_day]
          upload=Hash[upload_counts][date.beginning_of_day]
        end
        ui=pe-upload
        indicators_created[date.to_s[0..9]]=[pe,npe,upload,ui]
      end

      # Gather number of manual uploads
      # Have to do this one differently because Oracle is pretty stupid and can't handle the SQL that rails generates
      (s..e).each do |date|
        count=UploadedFile.where(created_at: date.beginning_of_day..date.end_of_day).joins(:user).where(users: {machine: false}).count
        manual_uploads[date.to_s[0..9]]=count
      end

      # Gather number of Packages created - broken out by NPE and PE, as well as via upload or UI
      pe=StixPackage.where(created_at: start_date..end_date).joins(:created_by_user).where(users: {machine: false}).order("#{group_by}(stix_packages.created_at) DESC").group("#{group_by}(stix_packages.created_at)").count.to_a
      npe=StixPackage.where(created_at: start_date..end_date).joins(:created_by_user).where(users: {machine: true}).order("#{group_by}(stix_packages.created_at) DESC").group("#{group_by}(stix_packages.created_at)").count.to_a
      upload=StixPackage.where(created_at: start_date..end_date).joins(:created_by_user).where(users: {machine: false}).joins(:uploaded_file).order("#{group_by}(stix_packages.created_at) DESC").group("#{group_by}(stix_packages.created_at)").uniq.count.to_a
      #UI - Subtract upload number from PE total
      (s..e).each do |date|
        pe=npe=upload=ui=0
        if Hash[pe_counts][date.beginning_of_day]
          pe=Hash[pe_counts][date.beginning_of_day]
        end
        if Hash[npe_counts][date.beginning_of_day]
          npe=Hash[npe_counts][date.beginning_of_day]
        end
        if Hash[upload_counts][date.beginning_of_day]
          upload=Hash[upload_counts][date.beginning_of_day]
        end
        ui=pe-upload
        packages_created[date.to_s[0..9]]=[pe,npe,upload,ui]
      end

      # Gather search logs
      search_counts = Logging::SearchLog.where(created_at: start_date..end_date).order("#{group_by}(created_at) DESC").group("#{group_by}(created_at)").count.to_a
      (s..e).each do |date|
        search=0
        if Hash[search_counts][date.beginning_of_day]
          search=Hash[search_counts][date.beginning_of_day]
        end
        search_logs[date.to_s[0..9]]=search
      end

      # Gather API calls - broken out by user
      api_counts=Logging::ApiLog.where(created_at: start_date..end_date).joins(:user).group("users.username").order("#{group_by}(api_logs.created_at) DESC").group("#{group_by}(api_logs.created_at)").pluck("#{group_by}(api_logs.created_at)","users.username","count(*)")
      list_of_users=[]
      temp_api={}
      api_counts.each do |a|
        list_of_users.push(a[1]) unless list_of_users.include?(a[1])
        temp_api[a[0].to_s[0..9]]={} unless temp_api[a[0].to_s[0..9]]
        temp_api[a[0].to_s[0..9]][a[1]]=a[2]
      end
      (s..e).each do |date|
        list_of_users.each do |user|
          api=0
          if temp_api[date.to_s] && temp_api[date.to_s][user]
            api=temp_api[date.to_s][user]
          end
          api_calls[date.to_s]={} unless api_calls[date.to_s]
          api_calls[date.to_s][user]=api
        end
      end
    end

    render json: {logins: logins, indicatorsCreated: indicators_created, manualUploads: manual_uploads, packagesCreated: packages_created, searchLogs: search_logs, apiCalls: api_calls}
  end
end
