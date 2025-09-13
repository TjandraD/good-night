# Development seeds with realistic but smaller dataset
require 'faker'

puts "Seeding development environment with realistic dataset..."

# Clear existing data first (be careful in production!)
puts "Clearing existing data..."
Follow.delete_all
SleepRecord.delete_all
User.delete_all

# Reset auto-increment sequences
ActiveRecord::Base.connection.reset_pk_sequence!('users')
ActiveRecord::Base.connection.reset_pk_sequence!('sleep_records')
ActiveRecord::Base.connection.reset_pk_sequence!('follows')

# Smaller numbers for development
USERS_COUNT = 10_000        # 10k users for development
SLEEP_RECORDS_COUNT = 50_000 # 50k sleep records (avg 5 per user)
FOLLOWS_COUNT = 20_000      # 20k follow relationships

BATCH_SIZE = 1_000          # Smaller batches for development

puts "Seeding #{USERS_COUNT} users..."
start_time = Time.current

# Process users in batches
(0...USERS_COUNT).each_slice(BATCH_SIZE) do |batch_range|
  users_batch = []
  
  batch_range.each do |index|
    users_batch << {
      name: Faker::Name.name,
      created_at: Faker::Time.between(from: 1.year.ago, to: Time.current),
      updated_at: Time.current
    }
  end
  
  User.insert_all(users_batch)
  puts "Inserted batch #{batch_range.first / BATCH_SIZE + 1} of #{(USERS_COUNT.to_f / BATCH_SIZE).ceil} for users"
end

users_time = Time.current - start_time
puts "Users seeded in #{users_time.round(2)} seconds"

# Get user IDs for referencing
user_ids = User.pluck(:id)

# Seed Sleep Records
puts "Seeding #{SLEEP_RECORDS_COUNT} sleep records..."
start_time = Time.current

(0...SLEEP_RECORDS_COUNT).each_slice(BATCH_SIZE) do |batch_range|
  sleep_records_batch = []
  
  batch_range.each do |index|
    user_id = user_ids.sample
    
    # Generate realistic sleep patterns
    bed_time = Faker::Time.between(from: 30.days.ago, to: Time.current)
    bed_time = bed_time.change(hour: rand(21..26) % 24, min: rand(0..59))
    
    # Wake up time should be 6-10 hours after bed time
    sleep_duration_hours = rand(6.0..10.0)
    wakeup_time = bed_time + sleep_duration_hours.hours
    
    sleep_records_batch << {
      user_id: user_id,
      bed_time: bed_time,
      wakeup_time: wakeup_time,
      created_at: bed_time + rand(0..3600).seconds,
      updated_at: Time.current
    }
  end
  
  SleepRecord.insert_all(sleep_records_batch)
  puts "Inserted batch #{batch_range.first / BATCH_SIZE + 1} of #{(SLEEP_RECORDS_COUNT.to_f / BATCH_SIZE).ceil} for sleep records"
end

sleep_records_time = Time.current - start_time
puts "Sleep records seeded in #{sleep_records_time.round(2)} seconds"

# Seed Follows
puts "Seeding #{FOLLOWS_COUNT} follow relationships..."
start_time = Time.current

existing_follows = Set.new

(0...FOLLOWS_COUNT).each_slice(BATCH_SIZE) do |batch_range|
  follows_batch = []
  
  batch_range.each do |index|
    max_attempts = 20
    attempts = 0
    
    while attempts < max_attempts
      follower_id = user_ids.sample
      followed_id = user_ids.sample
      
      if follower_id != followed_id && !existing_follows.include?([follower_id, followed_id])
        existing_follows.add([follower_id, followed_id])
        
        follows_batch << {
          follower_id: follower_id,
          followed_id: followed_id,
          created_at: Faker::Time.between(from: 6.months.ago, to: Time.current),
          updated_at: Time.current
        }
        break
      end
      
      attempts += 1
    end
  end
  
  if follows_batch.any?
    begin
      Follow.insert_all(follows_batch)
    rescue ActiveRecord::RecordNotUnique => e
      follows_batch.each do |follow_attrs|
        begin
          Follow.create!(follow_attrs)
        rescue ActiveRecord::RecordNotUnique
          # Skip duplicates
        end
      end
    end
  end
  
  puts "Inserted batch #{batch_range.first / BATCH_SIZE + 1} of #{(FOLLOWS_COUNT.to_f / BATCH_SIZE).ceil} for follows"
end

follows_time = Time.current - start_time
puts "Follow relationships seeded in #{follows_time.round(2)} seconds"

# Final statistics
puts "\n=== DEVELOPMENT SEEDING COMPLETED ==="
puts "Final counts:"
puts "Users: #{User.count}"
puts "Sleep Records: #{SleepRecord.count}"
puts "Follows: #{Follow.count}"

total_time = users_time + sleep_records_time + follows_time
puts "\nTotal seeding time: #{total_time.round(2)} seconds"

puts "\n=== SAMPLE DATA ==="
sample_user = User.includes(:sleep_records, :following, :followers).first
puts "Sample user: #{sample_user.name} (ID: #{sample_user.id})"
puts "  Sleep records: #{sample_user.sleep_records.count}"
puts "  Following: #{sample_user.following.count}"
puts "  Followers: #{sample_user.followers.count}"

puts "\nDevelopment seeding completed! 🚀"