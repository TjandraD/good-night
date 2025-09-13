require 'rails_helper'

RSpec.describe Follow, type: :model do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  describe 'associations' do
    it { should belong_to(:follower).class_name('User') }
    it { should belong_to(:followed).class_name('User') }
  end

  describe 'validations' do
    it { should validate_presence_of(:follower_id) }
    it { should validate_presence_of(:followed_id) }

    context 'uniqueness validation' do
      before { create(:follow, follower: user1, followed: user2) }
      
      it 'prevents duplicate follows' do
        duplicate_follow = build(:follow, follower: user1, followed: user2)
        expect(duplicate_follow).not_to be_valid
        expect(duplicate_follow.errors[:follower_id]).to include('already following this user')
      end

      it 'allows the same user to follow different users' do
        user3 = create(:user)
        follow = build(:follow, follower: user1, followed: user3)
        expect(follow).to be_valid
      end

      it 'allows different users to follow the same user' do
        user3 = create(:user)
        follow = build(:follow, follower: user3, followed: user2)
        expect(follow).to be_valid
      end
    end

    context 'self-follow validation' do
      it 'prevents a user from following themselves' do
        self_follow = build(:follow, follower: user1, followed: user1)
        expect(self_follow).not_to be_valid
        expect(self_follow.errors[:followed_id]).to include('cannot follow yourself')
      end
    end
  end

  describe 'valid follow creation' do
    it 'creates a valid follow relationship' do
      follow = create(:follow, follower: user1, followed: user2)
      expect(follow).to be_valid
      expect(follow.follower).to eq(user1)
      expect(follow.followed).to eq(user2)
    end
  end
end