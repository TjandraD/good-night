class ApplicationController < ActionController::API
  # Include Devise helpers for API authentication
  include ActionController::HttpAuthentication::Basic::ControllerMethods
  
  before_action :authenticate_user!

  private

  def authenticate_user!
    # Use Devise's built-in HTTP Basic Authentication
    # This leverages Devise's secure authentication while avoiding custom implementation
    authenticate_or_request_with_http_basic do |email, password|
      # Find user and validate using Devise's secure methods
      user = User.find_by(email: email)
      if user&.valid_for_authentication? { user.valid_password?(password) }
        @current_user = user
        true
      else
        false
      end
    end
  end

  def current_user
    @current_user
  end
end
