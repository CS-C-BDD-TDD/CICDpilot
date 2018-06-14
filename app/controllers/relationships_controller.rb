class RelationshipsController < ApplicationController
  def create
    @relationship = Relationship.new(relationship_params)

    unless Permissions.can_be_modified_by(current_user,@relationship.remote_src_object) && Permissions.can_be_modified_by(current_user,@relationship.remote_dest_object)
      render json: {errors: ["You do not have the ability to create a relationships between these two items"]}, status: 403
      return
    end

    if @relationship.save
      render "relationships/show.json.rabl"
    else
      render json: {errors: @relationship.errors}, status: :unprocessable_entity
    end
  end

  def update
    @relationship = Relationship.find_by_guid(params[:id])

    unless @relationship
      render json: {errors: 'Unable to find Relationship'},status: :bad_request
      return
    end

    unless Permissions.can_be_modified_by(current_user,@relationship.remote_src_object) && Permissions.can_be_modified_by(current_user,@relationship.remote_dest_object)
      render json: {errors: ["You do not have the ability to update the relationships between these two items"]}, status: 403
      return
    end

    if @relationship.update(relationship_params)
      render "relationships/show.json.rabl"
    else
      render json: {errors: @relationship.errors}, status: :unprocessable_entity
    end
  end

  def destroy
    @relationship = Relationship.find_by_guid(params[:id])

    unless @relationship
      render json: {errors: 'Unable to find Relationship'},status: :bad_request
      return
    end

    unless Permissions.can_be_modified_by(current_user,@relationship.remote_src_object) && Permissions.can_be_modified_by(current_user,@relationship.remote_dest_object)
      render json: {errors: ["You do not have the ability to delete the relationships between these two items"]}, status: 403
      return
    end

    if @relationship.destroy
      render json: {success: 'Relationship Removed', audits: @relationship.remote_src_object.audits}
    else
      render json: {errors: 'Unable to remove Relationship'}, status: :unprocessable_entity
    end
  end

  private

  def relationship_params
    params.permit(:relationship_type,
                  :stix_information_source_id,
                  :remote_src_object_guid,
                  :remote_src_object_type,
                  :remote_dest_object_guid,
                  :remote_dest_object_type,
                  :confidences_attributes => [:value,:is_official,:description, :source]
    )
  end
end