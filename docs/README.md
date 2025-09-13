# Good Night API - Postman Collection

This directory contains a comprehensive Postman collection for testing the Good Night API, a sleep tracking application that allows users to track their sleep patterns and follow other users to see their sleep records.

## Files

- `good-night-api.postman_collection.json` - Complete Postman collection with all API endpoints
- `openapi.yml` - OpenAPI 3.0 specification for the API

## How to Import and Use the Postman Collection

### 1. Import the Collection

1. Open Postman
2. Click the **Import** button (top left)
3. Choose **File** tab
4. Select the `good-night-api.postman_collection.json` file
5. Click **Import**

### 2. Set Up Environment Variables

The collection uses environment variables that you can customize:

- `base_url` - API base URL (default: `http://localhost:3000`)
- `user_id` - User ID for testing (default: `1`)
- `followed_id` - ID of user to follow/unfollow (default: `2`)

To set these variables:
1. Click the **Variables** tab in the collection
2. Update the **Current Value** column with your desired values
3. Click **Save**

### 3. API Endpoints Overview

The collection includes the following endpoints:

#### Health Check
- **GET /up** - Check if the application is running

#### Sleep Records
- **POST /api/v1/sleep_records** - Create new sleep record or update existing one with wakeup time

#### Follows
- **POST /api/v1/follows** - Follow a user
- **DELETE /api/v1/follows** - Unfollow a user
- **GET /api/v1/follows/sleep_records** - Get sleep records of followed users (with pagination)

### 4. Test Organization

The collection is organized into several folders:

#### Health Check
Basic health check endpoint for monitoring.

#### Sleep Records
Tests for creating and updating sleep records, including error cases.

#### Follows
Tests for follow/unfollow functionality and viewing followed users' sleep records, including pagination and error handling.

#### Test Scenarios
A complete user flow that demonstrates the full API functionality:
1. Create sleep records for users
2. Follow users
3. View followed users' sleep records
4. Update sleep records (waking up)
5. Unfollow users
6. Verify changes

### 5. Prerequisites

Before running the tests, ensure:

1. **Rails Application is Running**
   ```bash
   cd /path/to/good_night
   bin/rails server
   ```

2. **Database is Set Up**
   ```bash
   bin/rails db:setup
   bin/rails db:seed  # if you have seed data
   ```

3. **Test Users Exist**
   You'll need at least 3 users in your database. You can create them via Rails console:
   ```ruby
   bin/rails console
   User.create!(name: 'User One')
   User.create!(name: 'User Two')
   User.create!(name: 'User Three')
   ```

### 6. Running Tests

#### Individual Requests
1. Select any request from the collection
2. Click **Send**
3. Review the response and test results in the **Test Results** tab

#### Running All Tests
1. Click the **Runner** button in Postman
2. Select the "Good Night API" collection
3. Choose which requests to run (or run all)
4. Click **Run Good Night API**

#### Running Test Scenarios
For the best experience, run the **Complete User Flow** folder in sequence:
1. Right-click on "Complete User Flow" folder
2. Select **Run folder**
3. This will execute all steps in order

### 7. Understanding Test Results

Each request includes automated tests that verify:
- Correct HTTP status codes
- Response structure and required fields
- Business logic validation
- Error handling

Tests will show as **PASS** or **FAIL** with detailed information about what was tested.

### 8. Common Test Scenarios

#### Creating Sleep Records
1. **Going to Bed**: POST to `/api/v1/sleep_records` with a user_id creates a new sleep record
2. **Waking Up**: POST again with the same user_id updates the existing record with wakeup time

#### Following Users
1. **Follow**: POST to `/api/v1/follows` with user_id and followed_id
2. **View Sleep Records**: GET `/api/v1/follows/sleep_records` to see followed users' sleep records
3. **Unfollow**: DELETE `/api/v1/follows` with user_id and followed_id

#### Error Testing
The collection includes tests for common error scenarios:
- Non-existent users (401/404 errors)
- Invalid parameters (422 errors)
- Duplicate follows (422 errors)
- Self-follow attempts (422 errors)

### 9. Pagination Testing

The sleep records endpoint supports pagination:
- `page` parameter (default: 1)
- `limit` parameter (default: 25, max: 100)

The collection includes tests for different pagination scenarios.

### 10. Troubleshooting

#### Common Issues

**Connection Errors**
- Ensure Rails server is running on the correct port
- Check the `base_url` variable matches your server URL

**401 Unauthorized Errors**
- Verify that the user IDs in your requests exist in the database
- Check that you're using valid user_id values

**Empty Sleep Records**
- Ensure the user has followed other users
- Verify that followed users have sleep records

#### Database Reset
If you need to reset your test data:
```bash
bin/rails db:reset
bin/rails db:seed
```

### 11. API Documentation

For detailed API documentation, refer to the `openapi.yml` file in this directory, which provides:
- Complete endpoint specifications
- Request/response schemas
- Parameter descriptions
- Error response formats

### 12. Contributing

When adding new endpoints to the API:
1. Update the `openapi.yml` specification
2. Add corresponding requests to the Postman collection
3. Include appropriate test cases and error scenarios
4. Update this README with any new functionality

## Rate Limiting

The API includes rate limiting protection. If you encounter 429 errors, wait a moment before retrying requests.

## Support

For issues with the API or this Postman collection, please refer to the project repository or contact the development team.