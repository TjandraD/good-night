require 'rails_helper'

RSpec.describe Api::V1::SleepRecordsController, type: :controller do
  let(:user) { create(:user) }

  describe 'POST #create' do
    context 'when user_id is not provided' do
      it 'returns unauthorized error' do
        post :create
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to include(
          'error' => 'User not found',
          'message' => 'Please provide a valid user_id parameter'
        )
      end
    end

    context 'when user does not exist' do
      it 'returns unauthorized error' do
        post :create, params: { user_id: 999999 }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to include(
          'error' => 'User not found',
          'message' => 'Please provide a valid user_id parameter'
        )
      end
    end

    context 'when user exists' do
      context 'and user has no previous sleep records' do
        it 'creates a new sleep record with bed_time' do
          expect {
            post :create, params: { user_id: user.id }
          }.to change(SleepRecord, :count).by(1)

          expect(response).to have_http_status(:created)

          response_body = JSON.parse(response.body)
          expect(response_body['message']).to eq('Sleep record created successfully')

          sleep_record_data = response_body['sleep_record']
          expect(sleep_record_data['user_id']).to eq(user.id)
          expect(sleep_record_data['bed_time']).to be_present
          expect(sleep_record_data['wakeup_time']).to be_nil
          expect(sleep_record_data['sleeping']).to be true
          expect(sleep_record_data['duration_in_hours']).to be_nil
        end
      end

      context 'and user has a previous sleep record that is completed' do
        before do
          create(:sleep_record, :completed, user: user, created_at: 1.day.ago)
        end

        it 'creates a new sleep record' do
          expect {
            post :create, params: { user_id: user.id }
          }.to change(SleepRecord, :count).by(1)

          expect(response).to have_http_status(:created)

          response_body = JSON.parse(response.body)
          expect(response_body['message']).to eq('Sleep record created successfully')
          expect(response_body['sleep_record']['sleeping']).to be true
        end
      end

      context 'and user has a sleep record that is still in progress (no wakeup_time)' do
        let!(:current_sleep_record) { create(:sleep_record, user: user, bed_time: 1.hour.ago) }

        it 'updates the existing record with wakeup_time' do
          expect {
            post :create, params: { user_id: user.id }
          }.not_to change(SleepRecord, :count)

          expect(response).to have_http_status(:ok)

          response_body = JSON.parse(response.body)
          expect(response_body['message']).to eq('Wakeup time updated successfully')

          sleep_record_data = response_body['sleep_record']
          expect(sleep_record_data['id']).to eq(current_sleep_record.id)
          expect(sleep_record_data['wakeup_time']).to be_present
          expect(sleep_record_data['sleeping']).to be false
          expect(sleep_record_data['duration_in_hours']).to be_present
          expect(sleep_record_data['duration_in_hours']).to be > 0

          # Verify the record was actually updated in the database
          current_sleep_record.reload
          expect(current_sleep_record.wakeup_time).to be_present
        end
      end
    end
  end
end
