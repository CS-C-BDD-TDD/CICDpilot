class UserTagsController < ApplicationController
  before_filter -> {
    if !User.has_permission(current_user, 'tag_item_with_user_tag') 
      render json: {errors: ["You do not have permission to use user tags."]}, status: :forbidden
      return
    end
  }

  def create
    @user_tag = UserTag.new(tag_params)
    @user_tag.user_guid = current_user.guid
    if @user_tag.save
      render json: @user_tag
    else
      render json: {errors: @user_tag.errors},status: :unprocessable_entity
    end
  end

  def update
    @user_tag = (UserTag.where(guid: params[:id]).first || UserTag.where(name: params[:id]).first)

    if @user_tag.blank?
      render json: {errors: ["Could not find User Tag."]}, status: :not_found
      return
    end

    if params[:indicator_id]   
      indicator = Indicator.find_by_stix_id params[:indicator_id]
      if indicator.user_tags.where(guid: params[:id]).first.present?
        render json: @user_tag
        return
      end
      indicator.user_tags << @user_tag
      if indicator.save
        render json: @user_tag
      else
        render json: {errors: indicator.errors,status: :unprocessable_entity}
      end
    end
  end

  def index    
    if tag_params[:name]
      @user_tags = UserTag.where("tags.name LIKE ?" , "%#{tag_params[:name]}%")
    else
      @user_tags = UserTag.all
    end

    if params[:indicator_id]
      indicator = Indicator.find_by_stix_id params[:indicator_id]
      @user_tags = indicator.user_tags
    end

    @user_tags = @user_tags.where(user_guid:current_user.guid)
    render json: @user_tags
  end

  def show
    @user_tag = includes_indicators(UserTag.includes(:indicators,audits: :user))
    @user_tag = (@user_tag.where(guid: params[:id]).first || @user_tag.where(name: params[:id]).first)

    @indicators = @user_tag.indicators.limit(record_limit(params[:amount].to_i)).offset(params[:offset] || 0)

    total_count = @user_tag.indicators.count
    @metadata = Metadata.new
    @metadata.total_count = total_count

    respond_to do |format|
      format.html {render json: @user_tag, locals: {associations: {observables: 'embedded'}}}
      format.stix do
        stream = render_to_string(template: "user_tags/show.stix")
        send_data(stream, type: "text/xml", filename: "Indicators in #{@user_tag.name_normalized}.xml")
      end
      format.ais do
        stream = render_to_string(template: "user_tags/show.ais")
        send_data(stream, type: "text/xml", filename: "Indicators in #{@user_tag.name_normalized}.xml")
      end
    end
  end

  def destroy   
    @user_tag = (UserTag.where(guid: params[:id]).first || UserTag.where(name: params[:id]).first)

    if params[:indicator_id]
      indicator = Indicator.find_by_stix_id params[:indicator_id]
      @user_tag ||= UserTag.new
      if indicator.user_tags.where(guid: @user_tag.guid).first.blank?
        render json: @user_tag
        return
      end
      indicator.user_tags = indicator.user_tags.reject {|tag| tag.guid == @user_tag.guid}
      if indicator.save
        render json: @user_tag
      else
        render json: {errors: indicator.errors,status: :unprocessable_entity}
      end
      return
    end

    if @user_tag.destroy
      head :no_content
    else
      render json: {errors: @user_tag.errors,status: :unprocessable_entity}
    end    
  end

private

  def tag_params
    params.permit(:name)
  end

end
