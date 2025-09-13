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
end
