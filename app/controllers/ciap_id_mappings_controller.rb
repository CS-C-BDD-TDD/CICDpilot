class CiapIdMappingsController < ApplicationController
	wrap_parameters :ciap_id_mapping, include: [:original_id, :sanitized_id]
  	def index
  		@ciapMappings = CiapIdMapping.all
  		if params[:ebt].present? && params[:iet].present? 
  			@ciapMappings = @ciapMappings.where(created_at: params[:ebt]..params[:iet])
  		elsif params[:ebt].present? 
  			@ciapMappings = @ciapMappings.where('created_at  > ?', params[:ebt])
  		elsif params[:iet].present?   				  		
  			@ciapMappings = @ciapMappings.where('created_at < ?', params[:iet])
  		end  		
  		if params[:sanitized_id].present? 
  			@ciapMappings = @ciapMappings.where(:after_id => params[:sanitized_id])
  		end
  		if params[:original_id].present?
  			@ciapMappings = @ciapMappings.where(:before_id => params[:original_id])
  		end
  		render json:@ciapMappings
	end
	def create
		begin
			mappings_params = Array.new
			@ciapMappings = Array.new

			if !params[:ciap_id_mapping].blank? #only received one mapping entry, can check params as is
				mappings_params.push(create_params)
			else
				params[:_json].each do |cm| #put JSON objects into a ciap_id_mapping, then check params for each
					entryParams = ActionController::Parameters.new({ 
						ciap_id_mapping: {}.merge(cm)
					})
				mappings_params.push(create_mult_params(entryParams))			
				end
			end

			#check entries, create new mappings and return duplicates
			mappings_params.each do |mp|
				@ciapMapping = CiapIdMapping.where(:before_id => mp[:original_id], :after_id => mp[:sanitized_id]).first
				if !@ciapMapping 
					@ciapMapping = CiapIdMapping.create(mp)
					if !@ciapMapping.valid?
						render json: {errors: @ciapMapping.errors}, status: :unprocessable_entity
						return
					end				
				end
				@ciapMappings.push(@ciapMapping)			
			end
			@ciapMappings.each do |m| #all mappings valid, so save them
					m.save
			end			
			render json:@ciapMappings
			return
		rescue
			render json: {errors: $!.to_s}, status: :unprocessable_entity
			return			
		end
	end

    def create_params #parameter filtering/enforcing for when one entry is received
    	params.require(:ciap_id_mapping).permit([:original_id, :sanitized_id]).tap do |mparam| 
    		mparam.require(:original_id)
    		mparam.require(:sanitized_id)
    	end
    end	
    def create_mult_params(entry) #parameter filtering/enforcing for when multiple entries received
    	entry.require(:ciap_id_mapping).permit([:original_id, :sanitized_id]).tap do |mparam| 
    		mparam.require(:original_id)
    		mparam.require(:sanitized_id)
    	end
    end
end
