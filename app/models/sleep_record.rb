class SleepRecord < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true
  validates :bed_time, presence: true

  scope :with_wakeup, -> { where.not(wakeup_time: nil) }
  scope :without_wakeup, -> { where(wakeup_time: nil) }

  def duration_in_hours
    return nil unless bed_time && wakeup_time
    (wakeup_time - bed_time) / 1.hour
  end

  def sleeping?
    wakeup_time.nil?
  end
end
