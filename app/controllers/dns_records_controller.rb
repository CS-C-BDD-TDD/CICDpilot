class DnsRecordsController < ApplicationController
  include StixMarkingHelper
  
  def index
    @dns_records = DnsRecord.where(:cybox_object_id => params[:ids]) if params[:ids]
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
      search = Search.dns_record_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        classification_limit: params[:classification_limit],
        offset: solr_offset
      })

      if marking_search_params.present?
        @dns_records ||= DnsRecord.all.reorder(created_at: :desc)
        @dns_records = @dns_records.where(id: search.results.collect {|dr| dr.id})
      else
        total_count = search.total
        @dns_records = search.results
      end

      @dns_records ||= []
    else
      @dns_records ||= DnsRecord.all.reorder(created_at: :desc)

      @dns_records = @dns_records.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @dns_records = @dns_records.where(address_value_normalized: params[:address]) if params[:address].present?
      @dns_records = @dns_records.where(domain_normalized: params[:name]) if params[:name].present?
      @dns_records = @dns_records.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])

      @dns_records = apply_sort(@dns_records, params)
      @dns_records = @dns_records.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])
      @dns_records = @dns_records.classification_greater(params[:classification_greater]) if params[:classification_greater] && Classification::CLASSIFICATIONS.include?(params[:classification_greater])
    end
    
    if marking_search_params.present?
      @dns_records = @dns_records.joins(:stix_markings)
      @dns_records = add_stix_markings_constraints(@dns_records, marking_search_params)
    end

    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @dns_records.count
      @dns_records = @dns_records.limit(limit).offset(offset)
    end
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, dns_records: @dns_records} }
      format.csv {render "dns_records/index.csv.erb"}
    end
  end

  def show
    @dns_record = DnsRecord.includes(
        audits: :user,
        indicators: :confidences
    ).find_by_cybox_object_id(params[:id]) || 
    DnsRecord.includes(
      audits: :user,
      indicators: :confidences).find_by_cybox_hash(params[:id])
    if @dns_record
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      DnsRecord.apply_default_policy_if_needed(@dns_record)
      @dns_record.reload

      render json: @dns_record
    else
      render json: {errors: "Invalid DNS record number"}, status: 400
    end
  end

  def create
    if !User.has_permission(current_user, 'create_indicator_observable')
      render json: {errors: ["You do not have the ability to create DNS record observables"]}, status: 403
      return
    end
    @dns_record = DnsRecord.custom_save_or_update(dns_record_params)
    validate(@dns_record)
  end

  def update
    @dns_record = DnsRecord.find_by_cybox_object_id(params[:id])

    if !Permissions.can_be_modified_by(current_user,@dns_record)
      render json: {errors: ["You do not have the ability to modify this DNS record observable"]}, status: 403
      return
    end

    Audit.justification = params[:justification] if params[:justification]
    @dns_record = DnsRecord.custom_save_or_update(dns_record_params)
    validate(@dns_record)
   end

private
  def validate(object)
    if object.valid?
      render json: object
    else
      render json: {errors: object.errors}, status: :unprocessable_entity
    end
  end

  def dns_record_params
    if gfi_permitted?
      params.permit(:address_input,
                    :address_class,
                    :domain_input,
                    :entry_type,
                    :queried_date,
                    :guid,
                    :cybox_object_id,
                    :record_name,
                    :record_type,
                    :ttl,
                    :flags,
                    :data_length,
                    STIX_MARKING_PERMITTED_PARAMS,
                    :gfi_attributes=>GFI_ATTRIBUTES
                    )
    else
      params.permit(:address_input,
                    :address_class,
                    :domain_input,
                    :entry_type,
                    :queried_date,
                    :guid,
                    :record_name,
                    :record_type,
                    :ttl,
                    :flags,
                    :data_length,
                    STIX_MARKING_PERMITTED_PARAMS,
                    :cybox_object_id
                    )
    end
  end

end
