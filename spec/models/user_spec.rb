require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:sleep_records).dependent(:destroy) }
    it { should have_many(:active_follows).class_name('Follow').with_foreign_key('follower_id').dependent(:destroy) }
    it { should have_many(:passive_follows).class_name('Follow').with_foreign_key('followed_id').dependent(:destroy) }
    it { should have_many(:following).through(:active_follows).source(:followed) }
    it { should have_many(:followers).through(:passive_follows).source(:follower) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(100) }
  end

  describe '#latest_sleep_record' do
    let(:user) { create(:user) }

    context 'when user has no sleep records' do
      it 'returns nil' do
        expect(user.latest_sleep_record).to be_nil
      end
    end

    context 'when user has sleep records' do
      let!(:old_record) { create(:sleep_record, user: user, created_at: 2.days.ago) }
      let!(:recent_record) { create(:sleep_record, user: user, created_at: 1.day.ago) }

      it 'returns the most recent sleep record' do
        expect(user.latest_sleep_record).to eq(recent_record)
      end
    end
  end

  describe 'follow relationships' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    describe '#following?' do
      it 'returns false when not following' do
        expect(user1.following?(user2)).to be false
      end

      it 'returns true when following' do
        user1.follow(user2)
        expect(user1.following?(user2)).to be true
      end
    end

    describe '#follow' do
      it 'creates a follow relationship' do
        expect {
          user1.follow(user2)
        }.to change(Follow, :count).by(1)

        expect(user1.following?(user2)).to be true
        expect(user2.followers).to include(user1)
      end
    end

    describe 'follow collections' do
      before do
        user1.follow(user2)
        user1.follow(user3)
        user2.follow(user1)
      end

      it 'correctly identifies following relationships' do
        expect(user1.following).to contain_exactly(user2, user3)
        expect(user1.followers).to contain_exactly(user2)
        expect(user2.following).to contain_exactly(user1)
        expect(user2.followers).to contain_exactly(user1)
      end
    end

    describe '#unfollow' do
      context 'when follow relationship exists' do
        before { user1.follow(user2) }

        it 'removes the follow relationship' do
          expect {
            user1.unfollow(user2)
          }.to change(Follow, :count).by(-1)

          expect(user1.following?(user2)).to be false
          expect(user2.followers).not_to include(user1)
        end

        it 'returns the destroyed follow object' do
          follow = user1.active_follows.find_by(followed: user2)
          result = user1.unfollow(user2)
          expect(result).to eq(follow)
        end
      end

      context 'when follow relationship does not exist' do
        it 'returns nil and does not change follow count' do
          expect {
            result = user1.unfollow(user2)
            expect(result).to be_nil
          }.not_to change(Follow, :count)

          expect(user1.following?(user2)).to be false
        end
      end

      context 'with multiple follow relationships' do
        before do
          user1.follow(user2)
          user1.follow(user3)
          user3.follow(user1)
        end

        it 'only removes the specific follow relationship' do
          expect {
            user1.unfollow(user2)
          }.to change(Follow, :count).by(-1)

          expect(user1.following?(user2)).to be false
          expect(user1.following?(user3)).to be true
          expect(user3.following?(user1)).to be true
        end
      end
    end
  end
end
