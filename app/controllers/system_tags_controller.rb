class SystemTagsController < ApplicationController
  before_filter -> {
    if !User.has_permission(current_user, 'create_remove_system_tags')
      render json: {errors: ["You do not have permission to create or remove system tags."]}, status: :forbidden
      return
    end
  }, only: [:create,:update,:destroy]

  def create
    @system_tag = SystemTag.new(tag_params)
    if @system_tag.save
      render json: @system_tag
    else
      render json: {errors: @system_tag.errors},status: :unprocessable_entity
    end
  end

  def update
    @system_tag = (SystemTag.where(guid: params[:id]).first || SystemTag.where(name: params[:id]).first)

    if @system_tag.blank?
      render json: {errors: ["Could not find System Tag."]}, status: :not_found
      return
    end

    if params[:indicator_id]
      indicator = Indicator.find_by_stix_id params[:indicator_id]
      if indicator.system_tags.where(guid: params[:id]).first.present?
        render json: @system_tag
        return
      end
      indicator.system_tags << @system_tag
      if indicator.save
        render json: @system_tag
      else
        render json: {errors: indicator.errors,status: :unprocessable_entity}
      end
    end

  end


  def index
    if tag_params[:name]
      @system_tags = SystemTag.where("tags.name LIKE ?" , "%#{tag_params[:name]}%")
    else
      @system_tags = SystemTag.all
    end

    if params[:indicator_id]
      indicator = Indicator.find_by_stix_id params[:indicator_id]
      @system_tags = indicator.system_tags
    end
    
    render json: @system_tags
  end

  def show
    @system_tag = SystemTag.where(guid: params[:id]).includes(audits: :user)

    respond_to do |format|
      format.any(:html,:json) {@system_tag = @system_tag.first;render json: @system_tag, locals: {associations: {observables: 'embedded'}}}
      format.stix do
        @system_tag = includes_indicators(@system_tag)
        @system_tag = @system_tag.first
        stream = render_to_string(template: "system_tags/show.stix")
        send_data(stream, type: "text/xml", filename: "Indicators in #{@system_tag.name_normalized}.xml")
      end
      format.ais do
        @system_tag = includes_indicators(@system_tag)
        @system_tag = @system_tag.first
        stream = render_to_string(template: "system_tags/show.ais")
        send_data(stream, type: "text/xml", filename: "Indicators in #{@system_tag.name_normalized}.xml")
      end
    end
  end

  def destroy
    @system_tag = (SystemTag.where(guid: params[:id]).first || SystemTag.where(name: params[:id]).first)

    if params[:indicator_id]
      indicator = Indicator.find_by_stix_id params[:indicator_id]
      @system_tag ||= SystemTag.new
      if indicator.system_tags.where(guid: @system_tag.guid).first.blank?
        render json: @system_tag
        return
      end
      indicator.system_tags = indicator.system_tags.reject {|tag| tag.guid == @system_tag.guid}
      if indicator.save
        render json: @system_tag
      else
        render json: {errors: indicator.errors,status: :unprocessable_entity}
      end
      return
    end

    if @system_tag.is_permanent
      render json: {errors: "This tag is permanent, and cannot be deleted.",status: :forbidden}
      return
    end

    if !User.has_permission(current_user, 'create_remove_system_tags')
      render json: {errors: ["You do not have the ability to delete system tags"]}, status: 403
      return
    end

    if @system_tag.destroy
      head :no_content
    else
      render json: {errors: @system_tag.errors,status: :unprocessable_entity}
    end
  end

private

  def tag_params
    params.permit(:name,:user_id)
  end

end
