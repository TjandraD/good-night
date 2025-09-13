# Database Seeding Guide

This project includes a comprehensive database seeding system that can populate the database with millions of realistic records using the Faker gem.

## Quick Start

```bash
# Seed with environment-specific data
rails db:seed

# Seed with specific environment
RAILS_ENV=development rails db:seed
RAILS_ENV=production rails db:seed
RAILS_ENV=test rails db:seed
```

## Seeding Options

### 1. Environment-Specific Seeding

The seeding system automatically detects the current environment and loads appropriate data:

- **Development** (`db/seeds/development.rb`): 10K users, 50K sleep records, 20K follows
- **Production** (`db/seeds/production.rb`): 100 users, 500 sleep records, 200 follows  
- **Test** (`db/seeds/test.rb`): 5 users, 10 sleep records, 4 follows
- **Default** (`db/seeds.rb`): 1M users, 5M sleep records, 2M follows (massive dataset)

### 2. Performance Optimizations

The seeding system uses several optimizations for handling large datasets:

- **Bulk Inserts**: Uses `insert_all` for maximum performance
- **Batch Processing**: Processes records in batches to avoid memory issues
- **Garbage Collection**: Periodic GC to manage memory usage
- **Realistic Data**: Generates meaningful relationships and sleep patterns

### 3. Data Quality

The generated data includes:

- **Realistic Names**: Using Faker to generate diverse names
- **Realistic Sleep Patterns**: Bed times between 9 PM - 2 AM, 6-10 hour sleep duration
- **Unique Relationships**: Prevents duplicate follows and self-follows
- **Time Variance**: Records spread across different time periods

## Usage Examples

### Development Environment (Quick Setup)
```bash
RAILS_ENV=development rails db:seed
```
Creates 10K users with realistic data - perfect for development and testing.

### Production Environment (Minimal Data)
```bash
RAILS_ENV=production rails db:seed
```
Creates minimal data suitable for production verification.

### Performance Testing (Massive Dataset)
```bash
rails db:seed
```
Creates millions of records for performance testing and load simulation.

## Performance Metrics

Based on test runs, expected performance:

- **Users**: ~8,700 per second
- **Sleep Records**: ~7,500 per second  
- **Follows**: ~5,000 per second (due to uniqueness checks)

### Example Timing (1M users, 5M sleep records, 2M follows):
- Users: ~2 minutes
- Sleep Records: ~11 minutes
- Follows: ~7 minutes
- **Total**: ~20 minutes

## Database Schema

The seeding populates three main tables:

### Users
- `id`: Primary key
- `name`: Faker-generated name
- `created_at`, `updated_at`: Timestamps

### Sleep Records  
- `id`: Primary key
- `user_id`: Foreign key to users
- `bed_time`: Realistic bedtime (9 PM - 2 AM)
- `wakeup_time`: bed_time + 6-10 hours
- `created_at`, `updated_at`: Timestamps

### Follows
- `id`: Primary key  
- `follower_id`: User who follows
- `followed_id`: User being followed
- `created_at`, `updated_at`: Timestamps
- Unique constraint on (follower_id, followed_id)

## Memory Management

For large datasets, the seeding system:

1. Processes records in batches (10K by default)
2. Calls garbage collection every 10 batches
3. Clears duplicate tracking sets periodically
4. Uses efficient bulk insert operations

## Troubleshooting

### Out of Memory
Reduce `BATCH_SIZE` in the seed files or use environment-specific seeding.

### Slow Performance
Ensure you have adequate database resources and consider:
- Temporarily disabling database logging
- Using faster storage (SSD)
- Increasing database memory allocation

### Duplicate Key Errors
The system handles duplicates gracefully by falling back to individual inserts.

## Customization

To customize the seeding:

1. Edit the constants in `db/seeds/[environment].rb`:
   ```ruby
   USERS_COUNT = 50_000          # Adjust as needed
   SLEEP_RECORDS_COUNT = 250_000 # ~5 per user
   FOLLOWS_COUNT = 100_000       # ~2 per user
   BATCH_SIZE = 5_000           # Smaller = less memory
   ```

2. Modify the Faker data generation:
   ```ruby
   name: Faker::Name.unique.name,  # Ensure unique names
   name: "User #{index}",          # Sequential names
   ```

## Verification

After seeding, verify the data:

```bash
rails runner "
puts 'Users: ' + User.count.to_s
puts 'Sleep Records: ' + SleepRecord.count.to_s  
puts 'Follows: ' + Follow.count.to_s
puts 'Sample user: ' + User.includes(:sleep_records, :following).first.name
"
```