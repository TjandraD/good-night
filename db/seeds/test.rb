# Test seeds - minimal data for testing
require 'faker'

puts "Seeding test environment..."

# Clear existing data
Follow.delete_all
SleepRecord.delete_all
User.delete_all

# Minimal test data
users_data = [
  { name: "Test User 1" },
  { name: "Test User 2" },
  { name: "Test User 3" },
  { name: "Test User 4" },
  { name: "Test User 5" }
]

users_data.each { |attrs| attrs.merge!(created_at: Time.current, updated_at: Time.current) }
User.insert_all(users_data)

user_ids = User.pluck(:id)

# Create some test sleep records
sleep_records_data = []
user_ids.each do |user_id|
  2.times do |i|
    bed_time = (i + 1).days.ago.change(hour: 22)
    wakeup_time = bed_time + 8.hours

    sleep_records_data << {
      user_id: user_id,
      bed_time: bed_time,
      wakeup_time: wakeup_time,
      created_at: Time.current,
      updated_at: Time.current
    }
  end
end

SleepRecord.insert_all(sleep_records_data)

# Create some test follows
follows_data = [
  { follower_id: user_ids[0], followed_id: user_ids[1] },
  { follower_id: user_ids[0], followed_id: user_ids[2] },
  { follower_id: user_ids[1], followed_id: user_ids[0] },
  { follower_id: user_ids[2], followed_id: user_ids[3] }
]

follows_data.each { |attrs| attrs.merge!(created_at: Time.current, updated_at: Time.current) }
Follow.insert_all(follows_data)

puts "Test seeding completed!"
puts "Users: #{User.count}"
puts "Sleep Records: #{SleepRecord.count}"
puts "Follows: #{Follow.count}"
