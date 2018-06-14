class LayerSevenConnectionsController < ApplicationController

  def index
    limit = record_limit(params[:amount].to_i)
    offset = params[:offset] || 0

    if params[:q].present?
      search = Search.layer_seven_connections_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (limit || Sunspot.config.pagination.default_per_page),
        offset: offset,
        classification_limit: params[:classification_limit]
      })
      total_count = search.total
      @layer_seven_connections = search.results

      @layer_seven_connections ||= []
    else
      @layer_seven_connections = LayerSevenConnection.all.reorder(created_at: :desc)
      limit = record_limit(params[:amount].to_i)
      offset = params[:offset] || 0

      @layer_seven_connections = apply_sort(@layer_seven_connections, params)
      total_count = @layer_seven_connections.count
      @layer_seven_connections = @layer_seven_connections.limit(limit).offset(offset)
    end

    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, layer_seven_connections: @layer_seven_connections} }
    end
  end

  def create
    @layer_seven_connection = LayerSevenConnection.new(create_params)
    
    if @layer_seven_connection.valid?
      @layer_seven_connection.save
      render json:@layer_seven_connection
    else
      validation_errors = {:base => [], :errors => []}

      if @layer_seven_connection.errors.present?
        validation_errors[:errors] << @layer_seven_connection.errors.messages
      end

      # Look through all the dns_queries and find errors. Add them to the errors array.
      @layer_seven_connection.dns_queries.each do |obj|
        if obj.errors.messages.present? && obj.errors.messages[:base].present?
          obj.errors.messages[:base].each do |m|
            validation_errors[:base] << m
          end
        end
      end

      render json: {errors: validation_errors}, status: :unprocessable_entity 
    end
    return
  end

private

  def create_params 
    params.permit(
      :http_session_id, 
      :dns_query_cybox_object_ids => []
    )
  end 
end