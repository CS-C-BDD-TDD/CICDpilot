class ContributingSourcesController < ApplicationController
  def index
    @contributing_sources = ContributingSource.where({guid: params[:ids]}) if params[:ids]
    limit = record_limit(params[:amount].to_i)
    offset = params[:offset] || 0

    if params[:q].present?
      search = Search.contributing_source_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        limit: (limit || Sunspot.config.pagination.default_per_page),
        offset: offset
      })
      total_count = search.total
      @contributing_sources = search.results

      @contributing_sources ||= []

    else
      @contributing_sources ||= ContributingSource.all.reorder(guid: :desc)
  
      @contributing_sources = apply_sort(@contributing_sources, params)
      total_count = @contributing_sources.count
      @contributing_sources = @contributing_sources.limit(limit).offset(offset)
    end
    
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, contributing_sources: @contributing_sources} }
      format.csv { render "contributing_sources/index.csv.erb" }
    end
  end

  def show
    @contributing_source = ContributingSource.includes(
        audits: :user
    ).find_by_guid(params[:id])
      
    if @contributing_source
      render json: @contributing_source
    else
      render json: {errors: ["Invalid contributing source record number"]}, status: 400
    end
  end
end
