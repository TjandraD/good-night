class AddCompositeIndexToFollows < ActiveRecord::Migration[8.0]
  def change
    # Add composite index for efficient follow relationship lookups
    # This optimizes queries like: follows.where(follower_id: X, followed_id: Y)
    # Used in: FollowsController#destroy and Follow model uniqueness validation
    add_index :follows, [:follower_id, :followed_id], unique: true, name: 'index_follows_on_follower_and_followed'
    
    # Remove follower_id index since it's redundant with the composite index
    # Note: PostgreSQL can use the composite index for single-column lookups on follower_id
    remove_index :follows, :follower_id
  end
end
