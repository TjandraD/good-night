# Production seeds - minimal data for production environment
require 'faker'

puts "Seeding production environment with minimal essential data..."

# Only create a few users for testing in production
USERS_COUNT = 100
SLEEP_RECORDS_COUNT = 500
FOLLOWS_COUNT = 200

puts "Creating #{USERS_COUNT} test users..."

users_batch = []
(1..USERS_COUNT).each do |i|
  users_batch << {
    name: "User #{i}",
    created_at: Time.current,
    updated_at: Time.current
  }
end

User.insert_all(users_batch)
user_ids = User.pluck(:id)

puts "Creating #{SLEEP_RECORDS_COUNT} sleep records..."
sleep_records_batch = []
(1..SLEEP_RECORDS_COUNT).each do |i|
  user_id = user_ids.sample
  bed_time = 1.week.ago + rand(1.week)
  wakeup_time = bed_time + (6 + rand(4)).hours

  sleep_records_batch << {
    user_id: user_id,
    bed_time: bed_time,
    wakeup_time: wakeup_time,
    created_at: Time.current,
    updated_at: Time.current
  }
end

SleepRecord.insert_all(sleep_records_batch)

puts "Creating #{FOLLOWS_COUNT} follow relationships..."
follows_batch = []
existing = Set.new

(1..FOLLOWS_COUNT).each do |i|
  max_attempts = 10
  attempts = 0
  
  while attempts < max_attempts
    follower_id = user_ids.sample
    followed_id = user_ids.sample
    
    if follower_id != followed_id && !existing.include?([follower_id, followed_id])
      existing.add([follower_id, followed_id])
      follows_batch << {
        follower_id: follower_id,
        followed_id: followed_id,
        created_at: Time.current,
        updated_at: Time.current
      }
      break
    end
    attempts += 1
  end
end

Follow.insert_all(follows_batch) if follows_batch.any?

puts "\n=== PRODUCTION SEEDING COMPLETED ==="
puts "Users: #{User.count}"
puts "Sleep Records: #{SleepRecord.count}"
puts "Follows: #{Follow.count}"
puts "Production seeding completed! ✨"