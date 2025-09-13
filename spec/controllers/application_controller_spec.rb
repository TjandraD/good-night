require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller(ApplicationController) do
    # Skip authentication for this specific test action
    skip_before_action :authenticate_user!, only: [ :index ]

    def index
      render json: { message: 'Hello World' }
    end

    def show
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

  describe 'authentication' do
    let(:user) do
      User.create!(
        name: 'John Doe',
        email: 'john@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
    end

    before do
      routes.draw do
        get 'index' => 'anonymous#index'
        get 'show' => 'anonymous#show'
      end
    end

    context 'when user is not authenticated' do
      it 'returns 401 for protected endpoints' do
        get :show
        expect(response).to have_http_status(:unauthorized)
      end

      it 'allows access to unprotected endpoints' do
        get :index
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq('Hello World')
      end
    end

    context 'when user is authenticated with valid credentials' do
      before do
        credentials = Base64.encode64("#{user.email}:password123")
        request.headers['Authorization'] = "Basic #{credentials}"
      end

      it 'allows access to protected endpoints' do
        get :show
        expect(response).to have_http_status(:ok)

        response_body = JSON.parse(response.body)
        expect(response_body['message']).to eq('Authentication successful!')
        expect(response_body['user']['email']).to eq(user.email)
        expect(response_body['user']['name']).to eq(user.name)
      end
    end

    context 'when user is authenticated with invalid credentials' do
      before do
        credentials = Base64.encode64("#{user.email}:wrongpassword")
        request.headers['Authorization'] = "Basic #{credentials}"
      end

      it 'returns 401 for protected endpoints' do
        get :show
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user email does not exist' do
      before do
        credentials = Base64.encode64("nonexistent@example.com:password123")
        request.headers['Authorization'] = "Basic #{credentials}"
      end

      it 'returns 401 for protected endpoints' do
        get :show
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
