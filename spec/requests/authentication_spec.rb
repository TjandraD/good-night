require 'rails_helper'

RSpec.describe 'Authentication API', type: :request do
  let(:user) do
    User.create!(
      name: 'John Doe',
      email: 'john@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
  end

  describe 'GET /test_auth' do
    context 'when user is authenticated with valid credentials' do
      let(:headers) do
        credentials = Base64.encode64("#{user.email}:password123")
        { 'Authorization' => "Basic #{credentials}" }
      end

      it 'returns user information' do
        get '/test_auth', headers: headers

        expect(response).to have_http_status(:ok)
        
        response_body = JSON.parse(response.body)
        expect(response_body['message']).to eq('Authentication successful!')
        expect(response_body['user']['id']).to eq(user.id)
        expect(response_body['user']['email']).to eq(user.email)
        expect(response_body['user']['name']).to eq(user.name)
      end
    end

    context 'when user is not authenticated' do
      it 'returns 401 unauthorized' do
        get '/test_auth'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user provides invalid credentials' do
      let(:headers) do
        credentials = Base64.encode64("#{user.email}:wrongpassword")
        { 'Authorization' => "Basic #{credentials}" }
      end

      it 'returns 401 unauthorized' do
        get '/test_auth', headers: headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user email does not exist' do
      let(:headers) do
        credentials = Base64.encode64("nonexistent@example.com:password123")
        { 'Authorization' => "Basic #{credentials}" }
      end

      it 'returns 401 unauthorized' do
        get '/test_auth', headers: headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /up (health check)' do
    it 'returns 200 without authentication' do
      get '/up'
      
      expect(response).to have_http_status(:ok)
    end
  end
end