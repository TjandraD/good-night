require 'rails_helper'

RSpec.describe Rack::Attack do
  include Rack::Test::Methods

  def app
    Rails.application
  end

  before do
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    Rails.cache.clear
  end

  after do
    Rack::Attack.enabled = false
  end

  describe 'throttle excessive requests by IP' do
    let(:limit) { GoodNight::Application::RateLimit::NUMBER }

    context 'when request on any endpoint' do
      it 'throttle excessive requests' do
        (limit + 1).times do
          get '/up', env: {  'REMOTE_ADDR' => '1.2.3.5' }
        end

        expect(last_response.status).to eq(429)
      end
    end
  end
end
