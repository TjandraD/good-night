class User < ApplicationRecord
  has_many :sleep_records, dependent: :destroy

  # Follow relationships
  has_many :active_follows, class_name: "Follow", foreign_key: "follower_id", dependent: :destroy
  has_many :passive_follows, class_name: "Follow", foreign_key: "followed_id", dependent: :destroy
  has_many :following, through: :active_follows, source: :followed
  has_many :followers, through: :passive_follows, source: :follower

  validates :name, presence: true, length: { maximum: 100 }

  def latest_sleep_record
    sleep_records.order(id: :desc).first
  end

  def following?(other_user)
    following.include?(other_user)
  end

  def follow(other_user)
    active_follows.create(followed: other_user)
  end
end
