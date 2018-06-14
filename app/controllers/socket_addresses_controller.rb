class SocketAddressesController < ApplicationController
  include StixMarkingHelper
  
  def index
    @socket_addresses = SocketAddress.where(:cybox_object_id => params[:ids]) if params[:ids]
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
      search = Search.socket_address_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        offset: solr_offset,
        classification_limit: params[:classification_limit]
      })

      if marking_search_params.present?
        @socket_addresses ||= SocketAddress.all.reorder(created_at: :desc)
        @socket_addresses = @socket_addresses.where(id: search.results.collect {|addr| addr.id})
      else
        total_count = search.total
        @socket_addresses = search.results
      end

      @socket_addresses ||= []
    else
      @socket_addresses ||= SocketAddress.all.reorder(created_at: :desc)

      @socket_addresses = @socket_addresses.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @socket_addresses = apply_sort(@socket_addresses, params)
      @socket_addresses = @socket_addresses.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])
    end

    if marking_search_params.present?
      @socket_addresses = @socket_addresses.joins(:stix_markings)
      @socket_addresses = add_stix_markings_constraints(@socket_addresses, marking_search_params)
    end

    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @socket_addresses.count
      @socket_addresses = @socket_addresses.limit(limit).offset(offset)
    end
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, socket_addresses: @socket_addresses} }
      format.csv {render "socket_addresses/index.csv.erb"}
    end

  end

  def show
    @socket_address = SocketAddress.includes(
        audits: :user,
        indicators: :confidences
    )
    @socket_address = SocketAddress.find_by_cybox_object_id(params[:id]) || SocketAddress.find_by_cybox_hash(params[:id])
    if @socket_address
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      SocketAddress.apply_default_policy_if_needed(@socket_address)
      @socket_address.reload

      render json: @socket_address
    else
      render json: {errors: "Invalid Socket Address record number"}, status: 400
    end
  end

  def create
    if !User.has_permission(current_user, 'create_indicator_observable')
      render json: {errors: ["You do not have the ability to create Socket Address observables"]}, status: 403
      return
    end

    if User.has_permission(current_user,'create_indicator_observable')
      params[:address_cybox_object_ids] ||= []
      params[:hostname_cybox_object_ids] ||= []
      params[:port_cybox_object_ids] ||= []
    end
    
    @socket_address = SocketAddress.new(socket_address_params)
    
    if User.has_permission(current_user,'create_indicator_observable')
      @socket_address.address_cybox_object_ids = params[:address_cybox_object_ids] || []

      @socket_address.hostname_cybox_object_ids = params[:hostname_cybox_object_ids] || []

      @socket_address.port_cybox_object_ids = params[:port_cybox_object_ids] || []
    else
      if params[:address_cybox_object_ids].present? && params[:address_cybox_object_ids].length > 0
        render json: {errors: ["You do not have the ability to add addresses to socket addresses"]}, status: 403
        return
      end

      if params[:hostname_cybox_object_ids].present? && params[:hostname_cybox_object_ids].length > 0
        render json: {errors: ["You do not have the ability to add hostnames to socket addresses"]}, status: 403
        return
      end

      if params[:port_cybox_object_ids].present? && params[:port_cybox_object_ids].length > 0
        render json: {errors: ["You do not have the ability to add ports to socket addresses"]}, status: 403
        return
      end
    end

    validation_errors = {:base => []}

    begin
      @socket_address.save!
    rescue Exception => e
      validation_errors[:base] << e.to_s
    end

    if @socket_address.errors.present?
      validation_errors[:base] << @socket_address.errors.messages
    end

    # Look through all the addresses and find errors. Add them to the errors array.
    @socket_address.addresses.each do |obj|
      if obj.errors.messages.present? && obj.errors.messages[:base].present?
        obj.errors.messages[:base].each do |m|
          validation_errors[:base] << m
        end
      end
    end

    # Look through all the hostnames and find errors. Add them to the errors array.
    @socket_address.hostnames.each do |obj|
      if obj.errors.messages.present? && obj.errors.messages[:base].present?
        obj.errors.messages[:base].each do |m|
          validation_errors[:base] << m
        end
      end
    end

    # Look through all the ports and find errors. Add them to the errors array.
    @socket_address.ports.each do |obj|
      if obj.errors.messages.present? && obj.errors.messages[:base].present?
        obj.errors.messages[:base].each do |m|
          validation_errors[:base] << m
        end
      end
    end

    # if validate comes back with errors, we probably have a error
    if validation_errors[:base].blank?
      render json: @socket_address
    else
      render json: {errors: @socket_address.errors}, status: :unprocessable_entity
    end
  end

  def update
    @socket_address = SocketAddress.find_by_cybox_object_id(params[:id])

    unless Permissions.can_be_modified_by(current_user,@socket_address)
      render json: {errors: ["You do not have the ability to modify this Socket Address observable"]}, status: 403
      return
    end

    if Permissions.can_be_modified_by(current_user, @socket_address)
      @socket_address.address_cybox_object_ids = params[:address_cybox_object_ids] || []

      @socket_address.hostname_cybox_object_ids = params[:hostname_cybox_object_ids] || []

      @socket_address.port_cybox_object_ids = params[:port_cybox_object_ids] || []
    else
      if params[:address_cybox_object_ids].present? && params[:address_cybox_object_ids].length > 0
        render json: {errors: ["You do not have the ability to add addresses to socket addresses"]}, status: 403
        return
      end

      if params[:hostname_cybox_object_ids].present? && params[:hostname_cybox_object_ids].length > 0
        render json: {errors: ["You do not have the ability to add hostnames to socket addresses"]}, status: 403
        return
      end

      if params[:port_cybox_object_ids].present? && params[:port_cybox_object_ids].length > 0
        render json: {errors: ["You do not have the ability to add ports to socket addresses"]}, status: 403
        return
      end
    end

    Audit.justification = params[:justification] if params[:justification]
    @socket_address.update(socket_address_params)

    validation_errors = {:base => []}
    
    if @socket_address.errors.present?
      validation_errors[:base] << @socket_address.errors.messages
    end

    # Look through all the addresses and find errors. Add them to the errors array.
    @socket_address.addresses.each do |obj|
      if obj.errors.messages.present? && obj.errors.messages[:base].present?
        obj.errors.messages[:base].each do |m|
          validation_errors[:base] << m
        end
      end
    end

    # Look through all the hostnames and find errors. Add them to the errors array.
    @socket_address.hostnames.each do |obj|
      if obj.errors.messages.present? && obj.errors.messages[:base].present?
        obj.errors.messages[:base].each do |m|
          validation_errors[:base] << m
        end
      end
    end

    # Look through all the ports and find errors. Add them to the errors array.
    @socket_address.ports.each do |obj|
      if obj.errors.messages.present? && obj.errors.messages[:base].present?
        obj.errors.messages[:base].each do |m|
          validation_errors[:base] << m
        end
      end
    end

    # if validate comes back with errors, we probably have a error
    if validation_errors[:base].blank?
      render json: @socket_address
    else
      render json: {errors: @socket_address.errors}, status: :unprocessable_entity
    end
  end

private

  def socket_address_params
    params.permit(
      :guid,
      :cybox_object_id,
      STIX_MARKING_PERMITTED_PARAMS,
      :address_cybox_object_ids => [],
      :hostname_cybox_object_ids => [],
      :port_cybox_object_ids => []
    )
  end

end
