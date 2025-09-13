class Api::V1::FollowsController < Api::BaseController
  before_action :require_user

  def create
    followed_user = User.find_by(id: params[:followed_id])

    unless followed_user
      render json: {
        error: "User not found",
        message: "The user you want to follow does not exist"
      }, status: :not_found
      return
    end

    follow = current_user.active_follows.build(followed: followed_user)

    if follow.save
      render json: {
        message: "Successfully followed user",
        follow: follow_json(follow)
      }, status: :created
    else
      render json: {
        error: "Unable to follow user",
        message: follow.errors.full_messages.first
      }, status: :unprocessable_content
    end
  end

  def destroy
    followed_user = User.find_by(id: params[:followed_id])

    unless followed_user
      render json: {
        error: "User not found",
        message: "The user you want to unfollow does not exist"
      }, status: :not_found
      return
    end

    # Find the follow relationship
    follow = current_user.active_follows.find_by(followed: followed_user)

    unless follow
      render json: {
        error: "Follow relationship not found",
        message: "You are not following this user"
      }, status: :not_found
      return
    end

    if follow.destroy
      render json: {
        message: "Successfully unfollowed user",
        follow: follow_json(follow)
      }, status: :ok
    else
      render json: {
        error: "Unable to unfollow user",
        message: "An error occurred while unfollowing the user"
      }, status: :unprocessable_content
    end
  end

  private

  def follow_json(follow)
    {
      id: follow.id,
      follower_id: follow.follower_id,
      followed_id: follow.followed_id,
      follower_name: follow.follower.name,
      followed_name: follow.followed.name,
      created_at: follow.created_at.iso8601,
      updated_at: follow.updated_at.iso8601
    }
  end
end
