require 'rails_helper'

RSpec.describe Api::V1::FollowsController, type: :controller do
  let(:follower) { create(:user) }
  let(:followed) { create(:user) }

  describe 'POST #create' do
    context 'when user_id is not provided' do
      it 'returns unauthorized error' do
        post :create, params: { followed_id: followed.id }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to include(
          'error' => 'User not found',
          'message' => 'Please provide a valid user_id parameter'
        )
      end
    end

    context 'when user does not exist' do
      it 'returns unauthorized error' do
        post :create, params: { user_id: 999999, followed_id: followed.id }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to include(
          'error' => 'User not found',
          'message' => 'Please provide a valid user_id parameter'
        )
      end
    end

    context 'when followed_id is not provided' do
      it 'returns not found error' do
        post :create, params: { user_id: follower.id }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include(
          'error' => 'User not found',
          'message' => 'The user you want to follow does not exist'
        )
      end
    end

    context 'when followed user does not exist' do
      it 'returns not found error' do
        post :create, params: { user_id: follower.id, followed_id: 999999 }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include(
          'error' => 'User not found',
          'message' => 'The user you want to follow does not exist'
        )
      end
    end

    context 'when both users exist' do
      context 'and follow relationship does not exist' do
        it 'creates a new follow relationship and returns 201' do
          expect {
            post :create, params: { user_id: follower.id, followed_id: followed.id }
          }.to change(Follow, :count).by(1)

          expect(response).to have_http_status(:created)

          response_body = JSON.parse(response.body)
          expect(response_body['message']).to eq('Successfully followed user')

          follow_data = response_body['follow']
          expect(follow_data['follower_id']).to eq(follower.id)
          expect(follow_data['followed_id']).to eq(followed.id)
          expect(follow_data['follower_name']).to eq(follower.name)
          expect(follow_data['followed_name']).to eq(followed.name)
          expect(follow_data['id']).to be_present
          expect(follow_data['created_at']).to be_present
          expect(follow_data['updated_at']).to be_present
        end
      end

      context 'and follow relationship already exists' do
        before { create(:follow, follower: follower, followed: followed) }

        it 'returns unprocessable entity error' do
          expect {
            post :create, params: { user_id: follower.id, followed_id: followed.id }
          }.not_to change(Follow, :count)

          expect(response).to have_http_status(:unprocessable_content)

          response_body = JSON.parse(response.body)
          expect(response_body['error']).to eq('Unable to follow user')
          expect(response_body['message']).to eq('Follower already following this user')
        end
      end

      context 'when user tries to follow themselves' do
        it 'returns unprocessable entity error' do
          expect {
            post :create, params: { user_id: follower.id, followed_id: follower.id }
          }.not_to change(Follow, :count)

          expect(response).to have_http_status(:unprocessable_content)

          response_body = JSON.parse(response.body)
          expect(response_body['error']).to eq('Unable to follow user')
          expect(response_body['message']).to eq('Followed cannot follow yourself')
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user_id is not provided' do
      it 'returns unauthorized error' do
        delete :destroy, params: { followed_id: followed.id }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to include(
          'error' => 'User not found',
          'message' => 'Please provide a valid user_id parameter'
        )
      end
    end

    context 'when user does not exist' do
      it 'returns unauthorized error' do
        delete :destroy, params: { user_id: 999999, followed_id: followed.id }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to include(
          'error' => 'User not found',
          'message' => 'Please provide a valid user_id parameter'
        )
      end
    end

    context 'when followed_id is not provided' do
      it 'returns not found error' do
        delete :destroy, params: { user_id: follower.id }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include(
          'error' => 'User not found',
          'message' => 'The user you want to unfollow does not exist'
        )
      end
    end

    context 'when followed user does not exist' do
      it 'returns not found error' do
        delete :destroy, params: { user_id: follower.id, followed_id: 999999 }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include(
          'error' => 'User not found',
          'message' => 'The user you want to unfollow does not exist'
        )
      end
    end

    context 'when both users exist' do
      context 'and follow relationship exists' do
        before { create(:follow, follower: follower, followed: followed) }

        it 'destroys the follow relationship and returns 200' do
          expect {
            delete :destroy, params: { user_id: follower.id, followed_id: followed.id }
          }.to change(Follow, :count).by(-1)

          expect(response).to have_http_status(:ok)

          response_body = JSON.parse(response.body)
          expect(response_body['message']).to eq('Successfully unfollowed user')

          follow_data = response_body['follow']
          expect(follow_data['follower_id']).to eq(follower.id)
          expect(follow_data['followed_id']).to eq(followed.id)
          expect(follow_data['follower_name']).to eq(follower.name)
          expect(follow_data['followed_name']).to eq(followed.name)
          expect(follow_data['id']).to be_present
          expect(follow_data['created_at']).to be_present
          expect(follow_data['updated_at']).to be_present
        end
      end

      context 'and follow relationship does not exist' do
        it 'returns not found error' do
          expect {
            delete :destroy, params: { user_id: follower.id, followed_id: followed.id }
          }.not_to change(Follow, :count)

          expect(response).to have_http_status(:not_found)

          response_body = JSON.parse(response.body)
          expect(response_body['error']).to eq('Follow relationship not found')
          expect(response_body['message']).to eq('You are not following this user')
        end
      end
    end
  end

  describe 'GET #sleep_records' do
    let(:user1) { create(:user, name: 'User1') }
    let(:user2) { create(:user, name: 'User2') }
    let(:user3) { create(:user, name: 'User3') }
    let(:current_user) { create(:user, name: 'CurrentUser') }

    context 'when user_id is not provided' do
      it 'returns unauthorized error' do
        get :sleep_records
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to include(
          'error' => 'User not found',
          'message' => 'Please provide a valid user_id parameter'
        )
      end
    end

    context 'when user does not exist' do
      it 'returns unauthorized error' do
        get :sleep_records, params: { user_id: 999999 }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to include(
          'error' => 'User not found',
          'message' => 'Please provide a valid user_id parameter'
        )
      end
    end

    context 'when user exists but follows no one' do
      it 'returns empty sleep records with pagination' do
        get :sleep_records, params: { user_id: current_user.id }

        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)

        expect(response_body['message']).to eq('No sleep records found')
        expect(response_body['sleep_records']).to eq([])
        expect(response_body['pagination']).to include(
          'current_page' => 1,
          'per_page' => 25,
          'total_pages' => 0,
          'total_count' => 0
        )
      end
    end

    context 'when user follows others with sleep records' do
      let!(:follow1) { create(:follow, follower: current_user, followed: user1) }
      let!(:follow2) { create(:follow, follower: current_user, followed: user2) }
      let!(:sleep_record1) { create(:sleep_record, user: user1, bed_time: 2.days.ago, wakeup_time: 1.day.ago) }
      let!(:sleep_record2) { create(:sleep_record, user: user2, bed_time: 1.day.ago, wakeup_time: Time.current) }
      let!(:sleep_record3) { create(:sleep_record, user: user3, bed_time: 3.days.ago, wakeup_time: 2.days.ago) } # user3 not followed

      it 'returns sleep records from followed users only, ordered by bed_time desc' do
        get :sleep_records, params: { user_id: current_user.id }

        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)

        expect(response_body['message']).to eq('Sleep records retrieved successfully')
        expect(response_body['sleep_records'].length).to eq(2)

        # Check ordering (most recent bed_time first)
        sleep_records = response_body['sleep_records']
        expect(sleep_records[0]['user_id']).to eq(user2.id)
        expect(sleep_records[1]['user_id']).to eq(user1.id)

        # Check that user3's sleep record is not included
        user_ids = sleep_records.map { |sr| sr['user_id'] }
        expect(user_ids).not_to include(user3.id)

        # Check sleep record structure
        first_record = sleep_records[0]
        expect(first_record).to include(
          'id' => sleep_record2.id,
          'user_id' => user2.id,
          'user_name' => 'User2',
          'bed_time' => sleep_record2.bed_time.iso8601,
          'wakeup_time' => sleep_record2.wakeup_time.iso8601,
          'duration_in_hours' => sleep_record2.duration_in_hours,
          'sleeping' => false
        )

        # Check pagination
        expect(response_body['pagination']).to include(
          'current_page' => 1,
          'per_page' => 25,
          'total_pages' => 1,
          'total_count' => 2
        )
      end

      it 'handles pagination correctly' do
        # Ensure we have exactly 2 records for this test
        expect(SleepRecord.where(user_id: [ user1.id, user2.id ]).count).to eq(2)

        get :sleep_records, params: { user_id: current_user.id, page: 2, limit: 1 }

        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)

        expect(response_body['sleep_records'].length).to eq(1)
        expect(response_body['sleep_records'][0]['user_id']).to eq(user1.id)

        expect(response_body['pagination']).to include(
          'current_page' => 2,
          'per_page' => 1,
          'total_pages' => 2,
          'total_count' => 2
        )
      end

      it 'caps limit at 100' do
        get :sleep_records, params: { user_id: current_user.id, limit: 150 }

        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)

        expect(response_body['pagination']['per_page']).to eq(100)
      end

      it 'uses default values for invalid pagination parameters' do
        get :sleep_records, params: { user_id: current_user.id, page: -1, limit: 0 }

        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)

        expect(response_body['pagination']).to include(
          'current_page' => 1,
          'per_page' => 25
        )
      end

      it 'includes sleeping records correctly' do
        # Create a sleeping record (no wakeup_time)
        sleeping_record = create(:sleep_record, user: user1, bed_time: Time.current, wakeup_time: nil)

        get :sleep_records, params: { user_id: current_user.id }

        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)

        # Should now have 3 records (2 existing + 1 sleeping)
        expect(response_body['sleep_records'].length).to eq(3)

        # The sleeping record should be first (most recent bed_time)
        first_record = response_body['sleep_records'][0]
        expect(first_record['id']).to eq(sleeping_record.id)
        expect(first_record['sleeping']).to eq(true)
        expect(first_record['wakeup_time']).to be_nil
        expect(first_record['duration_in_hours']).to be_nil
      end
    end
  end
end
