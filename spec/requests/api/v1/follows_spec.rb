require 'rails_helper'

RSpec.describe 'Api::V1::Follows', type: :request do
  let(:follower) { create(:user) }
  let(:followed) { create(:user) }
  let(:headers) { { 'CONTENT_TYPE' => 'application/json' } }

  describe 'POST /api/v1/follows' do
    context 'when user_id is not provided' do
      it 'returns 401 unauthorized' do
        post '/api/v1/follows', params: { followed_id: followed.id }.to_json, headers: headers

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq({
          'error' => 'User not found',
          'message' => 'Please provide a valid user_id parameter'
        })
      end
    end

    context 'when user does not exist' do
      it 'returns 401 unauthorized' do
        post '/api/v1/follows', params: { user_id: 999999, followed_id: followed.id }.to_json, headers: headers

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq({
          'error' => 'User not found',
          'message' => 'Please provide a valid user_id parameter'
        })
      end
    end

    context 'when followed_id is not provided' do
      it 'returns 404 not found' do
        post '/api/v1/follows', params: { user_id: follower.id }.to_json, headers: headers

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to eq({
          'error' => 'User not found',
          'message' => 'The user you want to follow does not exist'
        })
      end
    end

    context 'when followed user does not exist' do
      it 'returns 404 not found' do
        post '/api/v1/follows', params: { user_id: follower.id, followed_id: 999999 }.to_json, headers: headers

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to eq({
          'error' => 'User not found',
          'message' => 'The user you want to follow does not exist'
        })
      end
    end

    context 'when both users exist' do
      context 'and follow relationship does not exist' do
        it 'creates a new follow relationship and returns 201' do
          expect {
            post '/api/v1/follows', params: { user_id: follower.id, followed_id: followed.id }.to_json, headers: headers
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

          # Verify the relationship was actually created in the database
          follow = Follow.last
          expect(follow.follower).to eq(follower)
          expect(follow.followed).to eq(followed)
        end
      end

      context 'and follow relationship already exists' do
        before { create(:follow, follower: follower, followed: followed) }

        it 'returns 422 unprocessable entity' do
          expect {
            post '/api/v1/follows', params: { user_id: follower.id, followed_id: followed.id }.to_json, headers: headers
          }.not_to change(Follow, :count)

          expect(response).to have_http_status(:unprocessable_content)

          response_body = JSON.parse(response.body)
          expect(response_body['error']).to eq('Unable to follow user')
          expect(response_body['message']).to eq('Follower already following this user')
        end
      end

      context 'when user tries to follow themselves' do
        it 'returns 422 unprocessable entity' do
          expect {
            post '/api/v1/follows', params: { user_id: follower.id, followed_id: follower.id }.to_json, headers: headers
          }.not_to change(Follow, :count)

          expect(response).to have_http_status(:unprocessable_content)

          response_body = JSON.parse(response.body)
          expect(response_body['error']).to eq('Unable to follow user')
          expect(response_body['message']).to eq('Followed cannot follow yourself')
        end
      end

      context 'integration test with user relationships' do
        it 'handles the complete follow flow' do
          # Step 1: Create follow relationship
          post '/api/v1/follows', params: { user_id: follower.id, followed_id: followed.id }.to_json, headers: headers

          expect(response).to have_http_status(:created)
          first_response = JSON.parse(response.body)
          expect(first_response['message']).to eq('Successfully followed user')

          follow_id = first_response['follow']['id']

          # Step 2: Verify relationship exists in database
          follower.reload
          followed.reload

          expect(follower.following).to include(followed)
          expect(followed.followers).to include(follower)
          expect(follower.following?(followed)).to be true

          # Step 3: Attempt duplicate follow (should fail)
          post '/api/v1/follows', params: { user_id: follower.id, followed_id: followed.id }.to_json, headers: headers

          expect(response).to have_http_status(:unprocessable_content)
          second_response = JSON.parse(response.body)
          expect(second_response['error']).to eq('Unable to follow user')

          expect(Follow.count).to eq(1)
        end
      end
    end
  end

  describe 'DELETE /api/v1/follows' do
    context 'when user_id is not provided' do
      it 'returns 401 unauthorized' do
        delete '/api/v1/follows', params: { followed_id: followed.id }.to_json, headers: headers

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq({
          'error' => 'User not found',
          'message' => 'Please provide a valid user_id parameter'
        })
      end
    end

    context 'when user does not exist' do
      it 'returns 401 unauthorized' do
        delete '/api/v1/follows', params: { user_id: 999999, followed_id: followed.id }.to_json, headers: headers

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq({
          'error' => 'User not found',
          'message' => 'Please provide a valid user_id parameter'
        })
      end
    end

    context 'when followed_id is not provided' do
      it 'returns 404 not found' do
        delete '/api/v1/follows', params: { user_id: follower.id }.to_json, headers: headers

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to eq({
          'error' => 'User not found',
          'message' => 'The user you want to unfollow does not exist'
        })
      end
    end

    context 'when followed user does not exist' do
      it 'returns 404 not found' do
        delete '/api/v1/follows', params: { user_id: follower.id, followed_id: 999999 }.to_json, headers: headers

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to eq({
          'error' => 'User not found',
          'message' => 'The user you want to unfollow does not exist'
        })
      end
    end

    context 'when both users exist' do
      context 'and follow relationship exists' do
        before { create(:follow, follower: follower, followed: followed) }

        it 'destroys the follow relationship and returns 200' do
          expect {
            delete '/api/v1/follows', params: { user_id: follower.id, followed_id: followed.id }.to_json, headers: headers
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

          # Verify the relationship was actually destroyed in the database
          expect(Follow.exists?(follower: follower, followed: followed)).to be false
        end
      end

      context 'and follow relationship does not exist' do
        it 'returns 404 not found' do
          expect {
            delete '/api/v1/follows', params: { user_id: follower.id, followed_id: followed.id }.to_json, headers: headers
          }.not_to change(Follow, :count)

          expect(response).to have_http_status(:not_found)

          response_body = JSON.parse(response.body)
          expect(response_body['error']).to eq('Follow relationship not found')
          expect(response_body['message']).to eq('You are not following this user')
        end
      end

      context 'integration test with complete follow/unfollow cycle' do
        it 'handles the complete follow and unfollow flow' do
          # Step 1: Create follow relationship
          post '/api/v1/follows', params: { user_id: follower.id, followed_id: followed.id }.to_json, headers: headers

          expect(response).to have_http_status(:created)
          follow_response = JSON.parse(response.body)
          expect(follow_response['message']).to eq('Successfully followed user')

          follow_id = follow_response['follow']['id']

          # Step 2: Verify relationship exists in database
          follower.reload
          followed.reload

          expect(follower.following).to include(followed)
          expect(followed.followers).to include(follower)
          expect(follower.following?(followed)).to be true
          expect(Follow.count).to eq(1)

          # Step 3: Unfollow the user
          delete '/api/v1/follows', params: { user_id: follower.id, followed_id: followed.id }.to_json, headers: headers

          expect(response).to have_http_status(:ok)
          unfollow_response = JSON.parse(response.body)
          expect(unfollow_response['message']).to eq('Successfully unfollowed user')

          # Verify the returned follow data matches what was deleted
          expect(unfollow_response['follow']['id']).to eq(follow_id)

          # Step 4: Verify relationship no longer exists
          follower.reload
          followed.reload

          expect(follower.following).not_to include(followed)
          expect(followed.followers).not_to include(follower)
          expect(follower.following?(followed)).to be false
          expect(Follow.count).to eq(0)

          # Step 5: Attempt to unfollow again (should fail)
          delete '/api/v1/follows', params: { user_id: follower.id, followed_id: followed.id }.to_json, headers: headers

          expect(response).to have_http_status(:not_found)
          second_unfollow_response = JSON.parse(response.body)
          expect(second_unfollow_response['error']).to eq('Follow relationship not found')
        end
      end
    end
  end

  describe 'GET /api/v1/follows/sleep_records' do
    let(:current_user) { create(:user, name: 'CurrentUser') }
    let(:user1) { create(:user, name: 'User1') }
    let(:user2) { create(:user, name: 'User2') }
    let(:user3) { create(:user, name: 'User3') }

    context 'when user_id is not provided' do
      it 'returns 401 unauthorized' do
        get '/api/v1/follows/sleep_records', headers: headers

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq({
          'error' => 'User not found',
          'message' => 'Please provide a valid user_id parameter'
        })
      end
    end

    context 'when user does not exist' do
      it 'returns 401 unauthorized' do
        get '/api/v1/follows/sleep_records', params: { user_id: 999999 }, headers: headers

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq({
          'error' => 'User not found',
          'message' => 'Please provide a valid user_id parameter'
        })
      end
    end

    context 'when user exists but follows no one' do
      it 'returns empty sleep records with correct pagination' do
        get '/api/v1/follows/sleep_records', params: { user_id: current_user.id }, headers: headers

        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)

        expect(response_body).to eq({
          'message' => 'No sleep records found',
          'sleep_records' => [],
          'pagination' => {
            'current_page' => 1,
            'per_page' => 25,
            'total_pages' => 0,
            'total_count' => 0
          }
        })
      end
    end

    context 'when user follows others with sleep records' do
      let!(:follow1) { create(:follow, follower: current_user, followed: user1) }
      let!(:follow2) { create(:follow, follower: current_user, followed: user2) }
      
      let!(:sleep_record1) do
        create(:sleep_record, 
               user: user1, 
               bed_time: 3.days.ago, 
               wakeup_time: 3.days.ago + 8.hours)
      end
      
      let!(:sleep_record2) do
        create(:sleep_record, 
               user: user2, 
               bed_time: 2.days.ago, 
               wakeup_time: 2.days.ago + 7.hours)
      end
      
      let!(:sleep_record3) do
        create(:sleep_record, 
               user: user1, 
               bed_time: 1.day.ago, 
               wakeup_time: 1.day.ago + 9.hours)
      end
      
      # User3 not followed by current_user
      let!(:sleep_record_unfollowed) do
        create(:sleep_record, 
               user: user3, 
               bed_time: 4.days.ago, 
               wakeup_time: 4.days.ago + 6.hours)
      end

      it 'returns sleep records from followed users ordered by bed_time desc' do
        get '/api/v1/follows/sleep_records', params: { user_id: current_user.id }, headers: headers

        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)

        expect(response_body['message']).to eq('Sleep records retrieved successfully')
        expect(response_body['sleep_records'].length).to eq(3)

        # Check ordering (most recent bed_time first)
        sleep_records = response_body['sleep_records']
        expect(sleep_records[0]['id']).to eq(sleep_record3.id) # 1 day ago
        expect(sleep_records[1]['id']).to eq(sleep_record2.id) # 2 days ago
        expect(sleep_records[2]['id']).to eq(sleep_record1.id) # 3 days ago

        # Verify only followed users' records are included
        user_ids = sleep_records.map { |sr| sr['user_id'] }
        expect(user_ids).to include(user1.id, user2.id)
        expect(user_ids).not_to include(user3.id)

        # Check first record structure
        first_record = sleep_records[0]
        expect(first_record).to include(
          'id' => sleep_record3.id,
          'user_id' => user1.id,
          'user_name' => 'User1',
          'bed_time' => sleep_record3.bed_time.iso8601,
          'wakeup_time' => sleep_record3.wakeup_time.iso8601,
          'sleeping' => false
        )
        expect(first_record['duration_in_hours']).to be_within(0.01).of(9.0)
        expect(first_record['created_at']).to be_present
        expect(first_record['updated_at']).to be_present

        # Check pagination
        expect(response_body['pagination']).to eq({
          'current_page' => 1,
          'per_page' => 25,
          'total_pages' => 1,
          'total_count' => 3
        })
      end

      it 'handles pagination correctly' do
        get '/api/v1/follows/sleep_records', 
            params: { user_id: current_user.id, page: 2, limit: 2 }, 
            headers: headers

        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)

        expect(response_body['sleep_records'].length).to eq(1)
        expect(response_body['sleep_records'][0]['id']).to eq(sleep_record1.id)

        expect(response_body['pagination']).to eq({
          'current_page' => 2,
          'per_page' => 2,
          'total_pages' => 2,
          'total_count' => 3
        })
      end

      it 'handles sleeping records (no wakeup_time) correctly' do
        # Create a sleeping record
        sleeping_record = create(:sleep_record, 
                                user: user1, 
                                bed_time: Time.current, 
                                wakeup_time: nil)

        get '/api/v1/follows/sleep_records', params: { user_id: current_user.id }, headers: headers

        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)

        expect(response_body['sleep_records'].length).to eq(4)

        # The sleeping record should be first (most recent bed_time)
        first_record = response_body['sleep_records'][0]
        expect(first_record['id']).to eq(sleeping_record.id)
        expect(first_record['sleeping']).to eq(true)
        expect(first_record['wakeup_time']).to be_nil
        expect(first_record['duration_in_hours']).to be_nil
      end

      it 'caps limit at 100 and uses defaults for invalid parameters' do
        get '/api/v1/follows/sleep_records', 
            params: { user_id: current_user.id, page: -1, limit: 150 }, 
            headers: headers

        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)

        expect(response_body['pagination']).to include(
          'current_page' => 1,  # Default to 1 for invalid page
          'per_page' => 100     # Capped at 100
        )
      end

      it 'handles edge case when followed user has no sleep records' do
        # Create a user with no sleep records
        user_no_sleep = create(:user, name: 'UserNoSleep')
        create(:follow, follower: current_user, followed: user_no_sleep)

        get '/api/v1/follows/sleep_records', params: { user_id: current_user.id }, headers: headers

        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)

        # Should still return the 3 existing sleep records
        expect(response_body['sleep_records'].length).to eq(3)
        expect(response_body['pagination']['total_count']).to eq(3)
      end
    end

    context 'integration test with complete follow and sleep tracking flow' do
      it 'handles the complete flow from following to viewing sleep records' do
        # Step 1: Follow user1 and user2
        post '/api/v1/follows', 
             params: { user_id: current_user.id, followed_id: user1.id }.to_json, 
             headers: headers
        expect(response).to have_http_status(:created)

        post '/api/v1/follows', 
             params: { user_id: current_user.id, followed_id: user2.id }.to_json, 
             headers: headers
        expect(response).to have_http_status(:created)

        # Step 2: Create sleep records for followed users
        sleep_record1 = create(:sleep_record, 
                              user: user1, 
                              bed_time: 1.day.ago, 
                              wakeup_time: 1.day.ago + 8.hours)
        
        sleep_record2 = create(:sleep_record, 
                              user: user2, 
                              bed_time: 2.hours.ago, 
                              wakeup_time: nil) # Currently sleeping

        # Create a sleep record for non-followed user (should not appear)
        create(:sleep_record, 
               user: user3, 
               bed_time: 3.hours.ago, 
               wakeup_time: 2.hours.ago)

        # Step 3: Fetch sleep records
        get '/api/v1/follows/sleep_records', params: { user_id: current_user.id }, headers: headers

        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)

        expect(response_body['sleep_records'].length).to eq(2)
        
        # Most recent should be first (user2's sleeping record)
        expect(response_body['sleep_records'][0]['user_id']).to eq(user2.id)
        expect(response_body['sleep_records'][0]['sleeping']).to eq(true)
        
        expect(response_body['sleep_records'][1]['user_id']).to eq(user1.id)
        expect(response_body['sleep_records'][1]['sleeping']).to eq(false)

        # Step 4: Unfollow user2
        delete '/api/v1/follows', 
               params: { user_id: current_user.id, followed_id: user2.id }.to_json, 
               headers: headers
        expect(response).to have_http_status(:ok)

        # Step 5: Fetch sleep records again (should only show user1's records)
        get '/api/v1/follows/sleep_records', params: { user_id: current_user.id }, headers: headers

        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)

        expect(response_body['sleep_records'].length).to eq(1)
        expect(response_body['sleep_records'][0]['user_id']).to eq(user1.id)
        expect(response_body['pagination']['total_count']).to eq(1)
      end
    end
  end
end
