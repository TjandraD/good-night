class Api::BaseController < ApplicationController
  # Common functionality for all API controllers
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

  private

  def not_found(exception)
    render json: { error: "Record not found", message: exception.message }, status: :not_found
  end

  def unprocessable_entity(exception)
    render json: { error: "Validation failed", message: exception.message }, status: :unprocessable_entity
  end

  def current_user
    # For now, we'll use a simple user lookup by user_id parameter
    # In a real app, this would use authentication tokens
    @current_user ||= User.find_by(id: params[:user_id]) if params[:user_id]
  end

  def require_user
    unless current_user
      render json: { error: "User not found", message: "Please provide a valid user_id parameter" }, status: :unauthorized
      return false
    end
    true
  end
end
