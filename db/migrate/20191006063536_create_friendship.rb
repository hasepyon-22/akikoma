class CreateFriendship < ActiveRecord::Migration[5.2]
  def change
    create_table :friendships do |t|
      t.references :user, index: true, foreign_key: true
      t.references :friend, foreign_key: true, foreign_key: {to_table: :users}
    end
  end
end
