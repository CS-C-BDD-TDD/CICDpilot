# Stores error messages and warnings associated with an an action such as a
# file upload.

class ErrorMessage < ActiveRecord::Base
  include Guidable
  include Transferable
end
