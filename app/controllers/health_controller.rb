class HealthController < ApplicationController
  # Skip authentication for health checks
  skip_before_action :authenticate_user!, only: [:show]

  def show
    render json: { status: 'ok' }, status: :ok
  end

  def test_auth
    render json: { 
      message: 'Authentication successful!', 
      user: {
        id: current_user.id,
        name: current_user.name,
        email: current_user.email
      }
    }
  end
end