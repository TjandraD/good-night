require 'rails_helper'

RSpec.describe HealthController, type: :controller do
  describe 'GET #show' do
    it 'returns health status without authentication' do
      get :show
      expect(response).to have_http_status(:ok)
      
      response_body = JSON.parse(response.body)
      expect(response_body['status']).to eq('ok')
    end
  end

  describe 'GET #test_auth' do
    let(:user) do
      User.create!(
        name: 'John Doe',
        email: 'john@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
    end

    context 'when user is not authenticated' do
      it 'returns 401 unauthorized' do
        get :test_auth
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated with valid credentials' do
      before do
        credentials = Base64.encode64("#{user.email}:password123")
        request.headers['Authorization'] = "Basic #{credentials}"
      end

      it 'returns user information' do
        get :test_auth
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

      it 'returns 401 unauthorized' do
        get :test_auth
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end