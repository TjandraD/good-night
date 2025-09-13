#!/usr/bin/env ruby

# Database verification script for good-night app
# Usage: rails runner db/verify_seed_data.rb

puts "🔍 Good Night App - Database Verification"
puts "========================================"
puts

# Basic counts
user_count = User.count
sleep_record_count = SleepRecord.count
follow_count = Follow.count

puts "📊 Record Counts:"
puts "  Users: #{user_count.to_s.reverse.gsub(/(\d{3})/, '\\1,').reverse.chomp(',')}"
puts "  Sleep Records: #{sleep_record_count.to_s.reverse.gsub(/(\d{3})/, '\\1,').reverse.chomp(',')}"
puts "  Follows: #{follow_count.to_s.reverse.gsub(/(\d{3})/, '\\1,').reverse.chomp(',')}"
puts

# Performance ratios
avg_sleep_per_user = (sleep_record_count.to_f / user_count).round(2)
avg_follows_per_user = (follow_count.to_f / user_count).round(2)

puts "📈 Data Distribution:"
puts "  Average sleep records per user: #{avg_sleep_per_user}"
puts "  Average follows per user: #{avg_follows_per_user}"
puts

# Sample user analysis
puts "👤 Sample User Analysis:"
sample_user = User.includes(:sleep_records, :following, :followers).first
if sample_user
  puts "  Name: #{sample_user.name}"
  puts "  ID: #{sample_user.id}"
  puts "  Sleep Records: #{sample_user.sleep_records.count}"
  puts "  Following: #{sample_user.following.count}"
  puts "  Followers: #{sample_user.followers.count}"
  
  if sample_user.sleep_records.any?
    recent_sleep = sample_user.sleep_records.order(created_at: :desc).first
    duration = ((recent_sleep.wakeup_time - recent_sleep.bed_time) / 1.hour).round(2)
    puts "  Recent Sleep:"
    puts "    Bed time: #{recent_sleep.bed_time.strftime('%Y-%m-%d %H:%M')}"
    puts "    Wake time: #{recent_sleep.wakeup_time.strftime('%Y-%m-%d %H:%M')}"
    puts "    Duration: #{duration} hours"
  end
else
  puts "  No users found in database"
end
puts

# Data quality checks
puts "✅ Data Quality Checks:"

# Check for users without sleep records
users_without_sleep = User.left_joins(:sleep_records).where(sleep_records: { id: nil }).count
puts "  Users without sleep records: #{users_without_sleep}"

# Check for users without any relationships
users_without_follows = User.left_joins(:active_follows, :passive_follows)
                           .where(follows: { id: nil })
                           .where(passive_follows_users: { id: nil })
                           .distinct.count
puts "  Users with no follow relationships: #{users_without_follows}"

# Check for invalid sleep durations (negative or too long)
invalid_sleep_records = SleepRecord.where.not(wakeup_time: nil)
                                   .where('wakeup_time <= bed_time OR wakeup_time > bed_time + INTERVAL \'24 hours\'')
                                   .count
puts "  Invalid sleep records: #{invalid_sleep_records}"

# Check for self-follows (should be 0)
self_follows = Follow.where('follower_id = followed_id').count
puts "  Self-follows (should be 0): #{self_follows}"

puts

# Recent activity
puts "📅 Recent Activity:"
recent_users = User.where('created_at > ?', 1.hour.ago).count
recent_sleep_records = SleepRecord.where('created_at > ?', 1.hour.ago).count
recent_follows = Follow.where('created_at > ?', 1.hour.ago).count

puts "  Users created in last hour: #{recent_users}"
puts "  Sleep records created in last hour: #{recent_sleep_records}"
puts "  Follows created in last hour: #{recent_follows}"
puts

# Database size estimation
if defined?(ActiveRecord::Base.connection.execute)
  begin
    result = ActiveRecord::Base.connection.execute("
      SELECT 
        schemaname,
        tablename,
        attname,
        n_distinct,
        correlation
      FROM pg_stats 
      WHERE schemaname = 'public' 
        AND tablename IN ('users', 'sleep_records', 'follows')
      ORDER BY tablename, attname
    ")
    
    if result.any?
      puts "📊 Database Statistics (PostgreSQL):"
      current_table = nil
      result.each do |row|
        if row['tablename'] != current_table
          puts "  #{row['tablename'].capitalize}:" if current_table
          current_table = row['tablename']
          puts "  #{current_table.capitalize}:"
        end
        puts "    #{row['attname']}: #{row['n_distinct']} distinct values (correlation: #{row['correlation']})"
      end
    end
  rescue => e
    puts "📊 Database Statistics: Not available (#{e.message})"
  end
end

puts
puts "🎉 Verification Complete!"
puts "========================"

if user_count > 0 && sleep_record_count > 0 && follow_count > 0 && self_follows == 0 && invalid_sleep_records == 0
  puts "✅ Database seeding appears successful!"
  puts "✅ All data quality checks passed!"
  puts "✅ Relationships are properly configured!"
else
  puts "⚠️  Some issues detected - please review the results above."
end