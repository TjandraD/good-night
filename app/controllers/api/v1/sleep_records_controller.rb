class Api::V1::SleepRecordsController < Api::BaseController
  before_action :require_user

  def create
    latest_record = current_user.latest_sleep_record

    # If there's a latest record and it doesn't have a wakeup_time, update it
    if latest_record&.sleeping?
      latest_record.update!(wakeup_time: Time.current)
      render json: {
        message: "Wakeup time updated successfully",
        sleep_record: sleep_record_json(latest_record)
      }, status: :ok
    else
      # Create a new sleep record
      new_record = current_user.sleep_records.create!(bed_time: Time.current)
      render json: {
        message: "Sleep record created successfully",
        sleep_record: sleep_record_json(new_record)
      }, status: :created
    end
  end

  private

  def sleep_record_json(record)
    {
      id: record.id,
      user_id: record.user_id,
      bed_time: record.bed_time&.iso8601,
      wakeup_time: record.wakeup_time&.iso8601,
      duration_in_hours: record.duration_in_hours,
      sleeping: record.sleeping?,
      created_at: record.created_at.iso8601,
      updated_at: record.updated_at.iso8601
    }
  end
end
