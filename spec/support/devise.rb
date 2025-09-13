# Devise test helpers configuration
require 'devise'

RSpec.configure do |config|
  # Include Devise test helpers for controller specs
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request

  # Configure Warden test helpers
  config.include Warden::Test::Helpers
  config.after :each do
    Warden.test_reset!
  end
end

# Helper method to authenticate users in tests
def authenticate_user(user, password = 'password123')
  credentials = Base64.encode64("#{user.email}:#{password}")
  { 'Authorization' => "Basic #{credentials}" }
end

# Factory methods for creating test users
def create_user(attributes = {})
  default_attributes = {
    name: 'Test User',
    email: 'test@example.com',
    password: 'password123',
    password_confirmation: 'password123'
  }
  User.create!(default_attributes.merge(attributes))
end