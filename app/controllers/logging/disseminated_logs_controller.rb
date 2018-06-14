class Logging::DisseminatedLogsController < ApplicationController
  def index
    disseminated=[]

    if params[:ebt] && params[:iet]
      ebt = params[:ebt].beginning_of_day
      iet = params[:iet].end_of_day

      group_by=ActiveRecord::Base.connection.instance_values["config"][:adapter]=='sqlite3'?'DATE':'TRUNC'
      records = Logging::Disseminate.joins(:disseminated_feeds)
                                    .where('disseminated_records.id=disseminated_feeds.disseminate_id')
                                    .where(disseminated_at: ebt..iet)
                                    .order("#{group_by}(disseminated_records.disseminated_at) desc")
                                    .group("#{group_by}(disseminated_records.disseminated_at)","disseminated_feeds.feed").count

      records.keys.sort.each do |d,f|
        disseminated << [d.to_s[0,10],f,records[[d,f]]]
      end
    end

    render json: {log: disseminated}
  end
end
