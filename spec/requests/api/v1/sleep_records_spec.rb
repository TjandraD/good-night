require 'rails_helper'

RSpec.describe 'Api::V1::SleepRecords', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:headers) { { 'CONTENT_TYPE' => 'application/json' } }

  describe 'POST /api/v1/sleep_records' do
    context 'when user_id is not provided' do
      it 'returns 401 unauthorized' do
        post '/api/v1/sleep_records', headers: headers

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq({
          'error' => 'User not found',
          'message' => 'Please provide a valid user_id parameter'
        })
      end
    end

    context 'when user does not exist' do
      it 'returns 401 unauthorized' do
        post '/api/v1/sleep_records', params: { user_id: 999999 }.to_json, headers: headers

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq({
          'error' => 'User not found',
          'message' => 'Please provide a valid user_id parameter'
        })
      end
    end

    context 'when user exists' do
      context 'and has no previous sleep records' do
        it 'creates a new sleep record and returns 201' do
          freeze_time = Time.parse('2023-12-25 22:00:00 UTC')

          travel_to(freeze_time) do
            expect {
              post '/api/v1/sleep_records', params: { user_id: user.id }.to_json, headers: headers
            }.to change(SleepRecord, :count).by(1)

            expect(response).to have_http_status(:created)

            response_body = JSON.parse(response.body)
            expect(response_body['message']).to eq('Sleep record created successfully')

            sleep_record = response_body['sleep_record']
            expect(sleep_record['user_id']).to eq(user.id)
            expect(sleep_record['bed_time']).to eq(freeze_time.iso8601)
            expect(sleep_record['wakeup_time']).to be_nil
            expect(sleep_record['sleeping']).to be true
            expect(sleep_record['duration_in_hours']).to be_nil
            expect(sleep_record['id']).to be_present
            expect(sleep_record['created_at']).to be_present
            expect(sleep_record['updated_at']).to be_present
          end
        end
      end

      context 'and has a completed sleep record' do
        before do
          create(:sleep_record, :completed, user: user, created_at: 1.day.ago)
        end

        it 'creates a new sleep record' do
          expect {
            post '/api/v1/sleep_records', params: { user_id: user.id }.to_json, headers: headers
          }.to change(SleepRecord, :count).by(1)

          expect(response).to have_http_status(:created)
          expect(JSON.parse(response.body)['message']).to eq('Sleep record created successfully')
        end
      end

      context 'and has an ongoing sleep record (no wakeup time)' do
        let!(:ongoing_record) do
          travel_to(Time.parse('2023-12-25 22:00:00 UTC')) do
            create(:sleep_record, user: user, bed_time: Time.current, wakeup_time: nil)
          end
        end

        it 'updates the existing record with wakeup time and returns 200' do
          freeze_time = Time.parse('2023-12-26 08:00:00 UTC')

          travel_to(freeze_time) do
            expect {
              post '/api/v1/sleep_records', params: { user_id: user.id }.to_json, headers: headers
            }.not_to change(SleepRecord, :count)

            expect(response).to have_http_status(:ok)

            response_body = JSON.parse(response.body)
            expect(response_body['message']).to eq('Wakeup time updated successfully')

            sleep_record = response_body['sleep_record']
            expect(sleep_record['id']).to eq(ongoing_record.id)
            expect(sleep_record['wakeup_time']).to eq(freeze_time.iso8601)
            expect(sleep_record['sleeping']).to be false
            expect(sleep_record['duration_in_hours']).to be_present
            expect(sleep_record['duration_in_hours']).to be > 0

            # Verify the record was actually updated in the database
            ongoing_record.reload
            expect(ongoing_record.wakeup_time).to be_within(1.second).of(freeze_time)
          end
        end
      end
    end

    context 'integration test with real flow' do
      it 'handles the complete sleep tracking flow' do
        # Step 1: Start sleep tracking
        post '/api/v1/sleep_records', params: { user_id: user.id }.to_json, headers: headers

        expect(response).to have_http_status(:created)
        first_response = JSON.parse(response.body)
        expect(first_response['message']).to eq('Sleep record created successfully')
        expect(first_response['sleep_record']['sleeping']).to be true

        sleep_record_id = first_response['sleep_record']['id']

        # Step 2: End sleep tracking (same endpoint call)
        post '/api/v1/sleep_records', params: { user_id: user.id }.to_json, headers: headers

        expect(response).to have_http_status(:ok)
        second_response = JSON.parse(response.body)
        expect(second_response['message']).to eq('Wakeup time updated successfully')
        expect(second_response['sleep_record']['id']).to eq(sleep_record_id)
        expect(second_response['sleep_record']['sleeping']).to be false
        expect(second_response['sleep_record']['duration_in_hours']).to be_present

        # Step 3: Start new sleep tracking (should create new record)
        post '/api/v1/sleep_records', params: { user_id: user.id }.to_json, headers: headers

        expect(response).to have_http_status(:created)
        third_response = JSON.parse(response.body)
        expect(third_response['message']).to eq('Sleep record created successfully')
        expect(third_response['sleep_record']['id']).not_to eq(sleep_record_id)
        expect(third_response['sleep_record']['sleeping']).to be true

        # Verify we have 2 sleep records total
        expect(user.sleep_records.count).to eq(2)
      end
    end
  end
end
