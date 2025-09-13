# Good Night 😴

A sleep tracking API that allows users to track their sleep patterns and follow other users to see their sleep records.

## 📖 Project Overview

Good Night is a Ruby on Rails API application that provides functionality for:
- Sleep record tracking (bedtime and wake-up times)
- Social features (following other users)
- Viewing friends' sleep records

## 🛠️ System Requirements

Before running this application, ensure you have the following installed:

- **Ruby**: 3.4.2 (recommended)
- **Rails**: 8.0.2
- **PostgreSQL**: 14+ (database)
- **Bundler**: 2.6.3+
- **Git**: For version control

### macOS Installation

```bash
# Install Ruby (using rbenv recommended)
brew install rbenv
rbenv install 3.4.2
rbenv global 3.4.2

# Install PostgreSQL
brew install postgresql@14
brew services start postgresql@14

# Install Bundler
gem install bundler
```

### Ubuntu/Debian Installation

```bash
# Install Ruby
sudo apt update
sudo apt install ruby-full

# Install PostgreSQL
sudo apt install postgresql postgresql-contrib

# Install Bundler
gem install bundler
```

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/TjandraD/good-night.git
cd good-night
```

### 2. Install Dependencies

```bash
bundle install
```

### 3. Database Setup

#### Configure Database
Ensure PostgreSQL is running, then:

```bash
# Create databases
bin/rails db:create

# Run migrations
bin/rails db:migrate

# Seed the database (optional)
bin/rails db:seed
```

#### Database Configuration
The application uses PostgreSQL by default. Update `config/database.yml` if you need custom database settings.

### 4. Environment Variables

Create a `.env` file in the project root for any environment-specific configurations. You can copy paste the existing `.env.example` and modify it as needed.:

```bash
# .env
DATABASE_URL=postgresql://username:password@localhost/good_night_development
RAILS_ENV=development
```

## 🏃‍♂️ How to Run

### Development Server

Start the Rails server:

```bash
bin/rails server
```

The application will be available at `http://localhost:3000`

### Using Docker (Alternative)

If you prefer using Docker:

```bash
# Build the image
docker build -t good-night .

# Run the container
docker run -p 3000:3000 good-night
```

## 🧪 How to Test

### Postman Collection

A Postman collection is provided in the `docs` folder to test the API endpoints.

### Running the Test Suite

This project uses RSpec for testing. Run the complete test suite:

```bash
# Run all tests
bundle exec rspec

# Run tests with coverage
bundle exec rspec --format documentation

# Run specific test file
bundle exec rspec spec/path/to/specific_spec.rb

# Run tests matching a pattern
bundle exec rspec --grep "user registration"
```

### Code Quality Tools

Run code quality checks:

```bash
# Ruby linting
bundle exec rubocop

# Security analysis
bundle exec brakeman

# Run all quality checks
bundle exec rubocop && bundle exec brakeman
```

### Test Database

The test database is automatically managed by RSpec, but you can manually reset it:

```bash
# Reset test database
RAILS_ENV=test bin/rails db:reset
```

## 📁 Database Schema

The application includes three main tables:

- **users**: Stores user information (id, name)
- **sleep_records**: Tracks sleep sessions (user_id, bedtime, wakeup_time)
- **follows**: Manages user follow relationships (follower_id, followed_id)

## 🏗️ Project Structure

```
good_night/
├── app/
│   ├── controllers/     # API controllers
│   ├── models/          # ActiveRecord models
│   ├── jobs/            # Background jobs
│   └── mailers/         # Email templates
├── config/              # Application configuration
├── db/
│   ├── migrate/         # Database migrations
│   └── schema.rb        # Current database schema
├── spec/                # RSpec tests
├── Gemfile              # Ruby dependencies
└── README.md           # This file
```

## 🔧 Development Tools

### Useful Commands

```bash
# Rails console
bin/rails console

# Generate migration
bin/rails generate migration MigrationName

# Check routes
bin/rails routes

# Database console
bin/rails dbconsole
```

### Debugging

The application includes the `debug` gem for debugging. Add breakpoints in your code:

```ruby
debugger  # This will pause execution
```

## 🚀 Deployment

The application is configured for deployment with:

- **Kamal**: For containerized deployment
- **Thruster**: For HTTP acceleration
- **PostgreSQL**: Production database

Refer to `config/deploy.yml` for deployment configuration.

## 📝 API Documentation

Once the application is running, API endpoints will be available at:

- Health check: `GET /up`
- (Additional endpoints will be documented as they are implemented)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b 123-feature/amazing-feature`)
3. Commit your changes, ensure you are using conventional commit (`git commit -m 'feat(#123): Add amazing feature'`)
4. Push to the branch (`git push origin 123-feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is part of a technical assessment.

---

For questions or issues, please open a GitHub issue or contact the development team.
