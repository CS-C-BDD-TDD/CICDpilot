module Ingestible extend ActiveSupport::Concern
  # included do |base|
  #   target_include = 'include Ingest::' + base.name
  #   eval(target_include)
  # end

	attr_writer :is_upload

	def is_upload
		if @is_upload.nil?
			false
		else
			@is_upload
		end
	end

  module ClassMethods
  end
end
