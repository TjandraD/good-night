require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      user = User.new(
        name: 'John Doe',
        email: 'john@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
      expect(user).to be_valid
    end

    it 'is not valid without a name' do
      user = User.new(
        email: 'john@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it 'is not valid without an email' do
      user = User.new(
        name: 'John Doe',
        password: 'password123',
        password_confirmation: 'password123'
      )
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it 'is not valid with a duplicate email' do
      User.create!(
        name: 'John Doe',
        email: 'john@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )

      user = User.new(
        name: 'Jane Doe',
        email: 'john@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("has already been taken")
    end

    it 'is not valid with a name longer than 100 characters' do
      user = User.new(
        name: 'a' * 101,
        email: 'john@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("is too long (maximum is 100 characters)")
    end
  end

  describe 'Devise modules' do
    let(:user) do
      User.create!(
        name: 'John Doe',
        email: 'john@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
    end

    it 'encrypts password' do
      expect(user.encrypted_password).to be_present
      expect(user.encrypted_password).not_to eq('password123')
    end

    it 'validates password correctly' do
      expect(user.valid_password?('password123')).to be true
      expect(user.valid_password?('wrongpassword')).to be false
    end
  end

  describe 'associations' do
    let(:user) { User.create!(name: 'John Doe', email: 'john@example.com', password: 'password123') }

    it 'has many sleep_records' do
      expect(user).to respond_to(:sleep_records)
    end

    it 'has many followers and following' do
      expect(user).to respond_to(:followers)
      expect(user).to respond_to(:following)
    end
  end
end
