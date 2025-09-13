class ApplicationController < ActionController::API
  # Include Devise methods for API controllers
  include ActionController::HttpAuthentication::Basic::ControllerMethods

  # Authentication requirement
  before_action :authenticate_user!

  private

  def authenticate_user!
    authenticate_or_request_with_http_basic do |email, password|
      user = User.find_by(email: email)
      if user&.valid_password?(password)
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
