class SourcesController < ApplicationController
  
	def get_by_package_id	
		params.permit(:id)
		@contributing_sources = []
		@contributing_sources = ContributingSource.where(stix_package_stix_id:params[:id])
		render @contributing_source
	end

    def create
      @contributing_source = ContributingSource.create(source_params)
      if @contributing_source.errors.blank?
        render json:@contributing_source
        return
      else
        render json: {errors: @contributing_source.errors}, status: :unprocessable_entity
      end
    end

  	def destroy
  		params.permit(:id)
    	@contributing_source = ContributingSource.find_by(guid:params[:id])
	    if @contributing_source
	    	if @contributing_source.destroy
      			render json: {success: 'Contributing Source deleted successfully'}
      		else
				render json: {errors:["Contributing source could not be deleted"] },status: :unprocessable_entity
      		end
	    else
	    	    render json: {errors:["Contributing source not found. Check guid"]}
    	end	   
	end

  	def show
		params.permit(:id)
		@contributing_source = []
		@contributing_source = ContributingSource.find_by(guid:params[:id])
		render json:@contributing_source  		
	end

	def update
	  	@contributing_source = ContributingSource.find_by(guid:params[:id])
      		@contributing_source.update(source_params)
		if @contributing_source.errors.blank?
	        	render json:@contributing_source
		else
			render json: {errors: @contributing_source.errors}, status: :unprocessable_entity
		end
        	return
	end

  	def index
  		@contributing_sources = ContributingSource.all
  		render json:@contributing_sources
	end

	def source_params
    	params.permit(:organization_names,
        	          :countries,
            	      :administrative_areas,
                	  :organization_info,
                  	  :is_federal,
                  	  :stix_package_stix_id
    	)
   end	
end
