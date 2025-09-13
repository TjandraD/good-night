# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Environment-specific seeding
puts "Loading seeds for #{Rails.env} environment..."

environment_seed_file = Rails.root.join('db', 'seeds', "#{Rails.env}.rb")

if File.exist?(environment_seed_file)
  puts "Loading environment-specific seeds from #{environment_seed_file}"
  load environment_seed_file
else
  puts "No environment-specific seed file found, loading default seeds..."

  # Default seeds (massive dataset) - same as before
  require 'faker'

  # Clear existing data first (be careful in production!)
  puts "Clearing existing data..."
  Follow.delete_all
  SleepRecord.delete_all
  User.delete_all

  # Reset auto-increment sequences (PostgreSQL specific)
  ActiveRecord::Base.connection.reset_pk_sequence!('users')
  ActiveRecord::Base.connection.reset_pk_sequence!('sleep_records')
  ActiveRecord::Base.connection.reset_pk_sequence!('follows')

  puts "Starting to seed the database with millions of records..."

  # Configuration for seeding
  USERS_COUNT = 1_000_000        # 1 million users
  SLEEP_RECORDS_COUNT = 5_000_000 # 5 million sleep records (avg 5 per user)
  FOLLOWS_COUNT = 2_000_000      # 2 million follow relationships

  BATCH_SIZE = 10_000            # Process in batches to avoid memory issues

  # Seed Users
  puts "Seeding #{USERS_COUNT} users..."
  start_time = Time.current

  # Process users in batches
  (0...USERS_COUNT).each_slice(BATCH_SIZE) do |batch_range|
    users_batch = []

    batch_range.each do |index|
      users_batch << {
        name: Faker::Name.name,
        created_at: Faker::Time.between(from: 2.years.ago, to: Time.current),
        updated_at: Time.current
      }
    end

    # Use insert_all for bulk insert (Rails 6+)
    User.insert_all(users_batch)

    puts "Inserted batch #{batch_range.first / BATCH_SIZE + 1} of #{(USERS_COUNT.to_f / BATCH_SIZE).ceil} for users"

    # Force garbage collection every few batches to manage memory
    GC.start if (batch_range.first / BATCH_SIZE + 1) % 10 == 0
  end

  users_time = Time.current - start_time
  puts "Users seeded in #{users_time.round(2)} seconds"

  # Get user IDs for referencing in sleep records and follows
  puts "Fetching user IDs for relationships..."
  user_ids = User.pluck(:id)
  puts "Found #{user_ids.count} user IDs"

  # Seed Sleep Records
  puts "Seeding #{SLEEP_RECORDS_COUNT} sleep records..."
  start_time = Time.current

  (0...SLEEP_RECORDS_COUNT).each_slice(BATCH_SIZE) do |batch_range|
    sleep_records_batch = []

    batch_range.each do |index|
      user_id = user_ids.sample

      # Generate realistic sleep patterns
      bed_time = Faker::Time.between(from: 30.days.ago, to: Time.current)
      # Adjust bed time to be realistic (between 9 PM and 2 AM)
      bed_time = bed_time.change(hour: rand(21..26) % 24, min: rand(0..59))

      # Wake up time should be 6-10 hours after bed time
      sleep_duration_hours = rand(6.0..10.0)
      wakeup_time = bed_time + sleep_duration_hours.hours

      sleep_records_batch << {
        user_id: user_id,
        bed_time: bed_time,
        wakeup_time: wakeup_time,
        created_at: bed_time + rand(0..3600).seconds, # Created shortly after bed time
        updated_at: Time.current
      }
    end

    SleepRecord.insert_all(sleep_records_batch)

    puts "Inserted batch #{batch_range.first / BATCH_SIZE + 1} of #{(SLEEP_RECORDS_COUNT.to_f / BATCH_SIZE).ceil} for sleep records"

    # Force garbage collection every few batches
    GC.start if (batch_range.first / BATCH_SIZE + 1) % 10 == 0
  end

  sleep_records_time = Time.current - start_time
  puts "Sleep records seeded in #{sleep_records_time.round(2)} seconds"

  # Seed Follows (Follow relationships)
  puts "Seeding #{FOLLOWS_COUNT} follow relationships..."
  start_time = Time.current

  # Track existing relationships to avoid duplicates
  existing_follows = Set.new

  (0...FOLLOWS_COUNT).each_slice(BATCH_SIZE) do |batch_range|
    follows_batch = []

    batch_range.each do |index|
      # Keep trying until we get a unique follow relationship
      max_attempts = 50
      attempts = 0

      while attempts < max_attempts
        follower_id = user_ids.sample
        followed_id = user_ids.sample

        # Ensure users don't follow themselves and relationship is unique
        if follower_id != followed_id && !existing_follows.include?([ follower_id, followed_id ])
          existing_follows.add([ follower_id, followed_id ])

          follows_batch << {
            follower_id: follower_id,
            followed_id: followed_id,
            created_at: Faker::Time.between(from: 1.year.ago, to: Time.current),
            updated_at: Time.current
          }
          break
        end

        attempts += 1
      end

      # If we can't find a unique relationship after max attempts, skip this one
      if attempts >= max_attempts
        puts "Warning: Skipped creating follow relationship after #{max_attempts} attempts"
      end
    end

    # Only insert if we have records in the batch
    if follows_batch.any?
      begin
        Follow.insert_all(follows_batch)
      rescue ActiveRecord::RecordNotUnique => e
        # Handle any remaining duplicate issues by inserting one by one
        puts "Batch insert failed due to duplicates, inserting individually..."
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

    # Force garbage collection and clear some memory every few batches
    if (batch_range.first / BATCH_SIZE + 1) % 5 == 0
      existing_follows.clear if existing_follows.size > 100_000 # Clear the set periodically to manage memory
      GC.start
    end
  end

  follows_time = Time.current - start_time
  puts "Follow relationships seeded in #{follows_time.round(2)} seconds"

  # Final statistics
  puts "\n=== SEEDING COMPLETED ==="
  puts "Final counts:"
  puts "Users: #{User.count}"
  puts "Sleep Records: #{SleepRecord.count}"
  puts "Follows: #{Follow.count}"

  total_time = users_time + sleep_records_time + follows_time
  puts "\nTotal seeding time: #{total_time.round(2)} seconds"
  puts "Average users per second: #{(User.count / users_time).round(2)}"
  puts "Average sleep records per second: #{(SleepRecord.count / sleep_records_time).round(2)}"
  puts "Average follows per second: #{(Follow.count / follows_time).round(2)}"

  puts "\n=== SAMPLE DATA ==="
  puts "Sample user:"
  sample_user = User.includes(:sleep_records, :following, :followers).first
  puts "  ID: #{sample_user.id}, Name: #{sample_user.name}"
  puts "  Sleep records: #{sample_user.sleep_records.count}"
  puts "  Following: #{sample_user.following.count}"
  puts "  Followers: #{sample_user.followers.count}"

  if sample_user.sleep_records.any?
    puts "\n  Recent sleep record:"
    recent_sleep = sample_user.sleep_records.order(created_at: :desc).first
    puts "    Bed time: #{recent_sleep.bed_time}"
    puts "    Wake time: #{recent_sleep.wakeup_time}"
    sleep_duration = ((recent_sleep.wakeup_time - recent_sleep.bed_time) / 1.hour).round(2)
    puts "    Duration: #{sleep_duration} hours"
  end

  puts "\nSeeding completed successfully! 🎉"
end
