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

  def sleep_records
    # Get pagination parameters
    page = [params[:page].to_i, 1].max
    limit = (params[:limit].present? && params[:limit].to_i > 0) ? params[:limit].to_i : 25
    limit = [limit, 100].min # Cap limit at 100
    offset = (page - 1) * limit

    # Get IDs of users that current user follows
    followed_user_ids = current_user.following.pluck(:id)

    if followed_user_ids.empty?
      render json: {
        message: "No sleep records found",
        sleep_records: [],
        pagination: {
          current_page: page,
          per_page: limit,
          total_pages: 0,
          total_count: 0
        }
      }, status: :ok
      return
    end

    # Get sleep records from followed users, ordered by bed_time desc (most recent first)
    sleep_records_query = SleepRecord.joins(:user)
                                    .where(user_id: followed_user_ids)
                                    .includes(:user)
                                    .order(bed_time: :desc)

    # Get total count for pagination
    total_count = sleep_records_query.count
    total_pages = (total_count.to_f / limit).ceil

    # Apply pagination
    sleep_records = sleep_records_query.limit(limit).offset(offset)

    render json: {
      message: "Sleep records retrieved successfully",
      sleep_records: sleep_records.map { |record| sleep_record_with_user_json(record) },
      pagination: {
        current_page: page,
        per_page: limit,
        total_pages: total_pages,
        total_count: total_count
      }
    }, status: :ok
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

  def sleep_record_with_user_json(record)
    {
      id: record.id,
      user_id: record.user_id,
      user_name: record.user.name,
      bed_time: record.bed_time&.iso8601,
      wakeup_time: record.wakeup_time&.iso8601,
      duration_in_hours: record.duration_in_hours,
      sleeping: record.sleeping?,
      created_at: record.created_at.iso8601,
      updated_at: record.updated_at.iso8601
    }
  end
end
