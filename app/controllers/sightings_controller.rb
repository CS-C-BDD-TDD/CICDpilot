class SightingsController < ApplicationController
  
  def show
    @sighting = Sighting.find_by_guid(params[:id])
    if @sighting
      render json: @sighting
    else
      render json: {errors: ['Invalid sighting record number']}, status: 400
    end
  end

  def create
    @sighting = Sighting.create(sighting_params)
    if @sighting.valid?
      render json: @sighting
      return
    else
      render json: {errors: @sighting.errors}, status: :unprocessable_entity
    end
  end


  def destroy
    @sighting = Sighting.find_by_guid(params[:id])
    if @sighting.destroy
      render json: {success: 'Sighting Deleted'}
    else
      render json: {errors: ["Unable to Delete #{@sighting.guid}"]},
             status: :unprocessable_entity
    end
  end

  private

  def sighting_params

    params.permit(:id,
                  :description,
                  :sighted_at,
                  :stix_indicator_id,
                  :guid,
                  :confidences_attributes => [:value, :is_official,
                                              :description, :source]
    )
  end

end
