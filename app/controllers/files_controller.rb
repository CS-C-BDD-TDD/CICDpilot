class FilesController < ApplicationController
  include StixMarkingHelper
  
  def index
    @files = CyboxFile.where(:cybox_object_id => params[:ids]) if params[:ids]
    limit = record_limit(params[:amount].to_i)
    offset = params[:offset] || 0
    marking_search_params = nil
    if params[:marking_search_params].present?
      marking_search_params = JSON.parse params[:marking_search_params]
    end

    if params[:q].present?
      solr_offset = offset
      solr_limit = limit
      
      # If performing a SOLR based search AND a Stix Marking search we need to do a two-step query
      # First, we perform the SOLR based query and grab the ids of the first 1000 results.
      # We use those IDs to limit the SQL query that will feed the Stix Marking search
      if marking_search_params.present?
        solr_offset = 0
        solr_limit = 1000
      end
      search = Search.cybox_file_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        classification_limit: params[:classification_limit],
        offset: solr_offset
      })

      if marking_search_params.present?
        @files ||= CyboxFile.all.reorder(created_at: :desc)
        @files = @files.where(id: search.results.collect {|fil| fil.id})
      else
        total_count = search.total
        @files = search.results
      end

      @files ||= []
    else
      @files ||= CyboxFile.all.reorder(created_at: :desc)

      @files = @files.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @files = @files.where(file_name: params[:name]) if params[:name].present?
      @files = @files.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])

      @files = apply_sort(@files, params)
    end

    if marking_search_params.present?
      @files = @files.joins(:stix_markings)
      @files = add_stix_markings_constraints(@files, marking_search_params)
    end

    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @files.count
      @files = @files.limit(limit).offset(offset)
    end
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {files: @files, metadata: @metadata} }
      format.csv {render "files/index.csv.erb"}
    end
  end

  def show
    @file = CyboxFile.includes(
        audits: :user,
        indicators: :confidences
    ).find_by_cybox_object_id(params[:id])
    if @file
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      CyboxFile.apply_default_policy_if_needed(@file)
      @file.reload

      render json: @file
    else
      render json: {errors: "Invalid file record number"}, status: 400
    end
  end

  def create
    if !User.has_permission(current_user, 'create_indicator_observable')
      render json: {errors: ["You do not have the ability to create file observables"]}, status: 403
      return
    end
    @file = CyboxFile.special_markings_create_or_update(nil, file_params)
    if @file.valid?
      render(json: @file) 
    else
      render json: {errors: @file.errors}, status: :unprocessable_entity
    end
  end

  def update
    unless User.has_permission(current_user, 'create_indicator_observable')
      render json: {errors: ["You do not have the ability to create file observables"]}, status: 403
      return
    end

    @file = CyboxFile.find_by_cybox_object_id(params[:id])

    Audit.justification = params[:justification] if params[:justification]
    @file = CyboxFile.special_markings_create_or_update(@file, file_params)

    if @file.errors.present?
      render json: {errors: @file.errors}, status: :unprocessable_entity
    else
      render(json: @file)
    end
  end

private

  def file_params
    if gfi_permitted?
      params.permit(
          :file_name,
          :file_name_condition,
          :file_path,
          :file_path_condition,
          :size_in_bytes,
          :size_in_bytes_condition,
          :guid,
          :cybox_object_id,
          STIX_MARKING_PERMITTED_PARAMS,
          :gfi_attributes=>GFI_ATTRIBUTES,
          :file_hashes_attributes=>[:hash_type,:simple_hash_value, :fuzzy_hash_value,:id,:_destroy]
      )
    else
      params.permit(
          :file_name,
          :file_name_condition,
          :file_path,
          :file_path_condition,
          :size_in_bytes,
          :size_in_bytes_condition,
          :guid,
          :cybox_object_id,
          STIX_MARKING_PERMITTED_PARAMS,
          :file_hashes_attributes=>[:hash_type,:simple_hash_value,:fuzzy_hash_value,:id,:_destroy]
      )
    end
  end
end
