require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:sleep_records).dependent(:destroy) }
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
end
