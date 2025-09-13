class User < ApplicationRecord
  has_many :sleep_records, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }

  def latest_sleep_record
    sleep_records.order(created_at: :desc).first
  end
end
