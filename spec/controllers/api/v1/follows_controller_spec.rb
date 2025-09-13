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
end
