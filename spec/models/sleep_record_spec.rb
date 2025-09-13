require 'rails_helper'

RSpec.describe SleepRecord, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:bed_time) }
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let!(:record_with_wakeup) { create(:sleep_record, user: user, wakeup_time: Time.current) }
    let!(:record_without_wakeup) { create(:sleep_record, user: user, wakeup_time: nil) }

    describe '.with_wakeup' do
      it 'returns records with wakeup time' do
        expect(SleepRecord.with_wakeup).to include(record_with_wakeup)
        expect(SleepRecord.with_wakeup).not_to include(record_without_wakeup)
      end
    end

    describe '.without_wakeup' do
      it 'returns records without wakeup time' do
        expect(SleepRecord.without_wakeup).to include(record_without_wakeup)
        expect(SleepRecord.without_wakeup).not_to include(record_with_wakeup)
      end
    end
  end

  describe '#duration_in_hours' do
    let(:sleep_record) { build(:sleep_record) }

    context 'when both bed_time and wakeup_time are present' do
      it 'calculates the duration in hours' do
        sleep_record.bed_time = Time.parse('2023-01-01 22:00:00')
        sleep_record.wakeup_time = Time.parse('2023-01-02 08:00:00')
        expect(sleep_record.duration_in_hours).to eq(10.0)
      end
    end

    context 'when wakeup_time is missing' do
      it 'returns nil' do
        sleep_record.bed_time = Time.current
        sleep_record.wakeup_time = nil
        expect(sleep_record.duration_in_hours).to be_nil
      end
    end

    context 'when bed_time is missing' do
      it 'returns nil' do
        sleep_record.bed_time = nil
        sleep_record.wakeup_time = Time.current
        expect(sleep_record.duration_in_hours).to be_nil
      end
    end
  end

  describe '#sleeping?' do
    let(:sleep_record) { build(:sleep_record) }

    context 'when wakeup_time is nil' do
      it 'returns true' do
        sleep_record.wakeup_time = nil
        expect(sleep_record.sleeping?).to be true
      end
    end

    context 'when wakeup_time is present' do
      it 'returns false' do
        sleep_record.wakeup_time = Time.current
        expect(sleep_record.sleeping?).to be false
      end
    end
  end
end
