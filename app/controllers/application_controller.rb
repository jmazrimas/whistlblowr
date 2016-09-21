class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def after_sign_in_path_for(resource)
    complaints_path
  end

  # check_authorization :unless => :devise_controller?  # This will raise an exception if authorization is not performed in an action.

end
