class AddIndexToSleepRecordsBedTime < ActiveRecord::Migration[8.0]
  def change
    # Add index on bed_time for efficient ordering in the follows/sleep_records endpoint
    # This optimizes queries like: sleep_records.order(bed_time: :desc)
    # Used in: FollowsController#sleep_records for chronological ordering
    add_index :sleep_records, :bed_time, name: 'index_sleep_records_on_bed_time'
  end
end
