require 'bundler/setup'
Bundler.require

if development?
  ActiveRecord::Base.establish_connection("sqlite3:db/development.db")
end

class User < ActiveRecord::Base
  has_secure_password
  has_many :users_lectures
  has_many :lectures, :through => :users_lectures

  has_many :friendships
  has_many :friend_friendships, class_name: 'Friendship', foreign_key: 'friend_id'
  #has_many :friends, through: :friendships
end

class Lecture < ActiveRecord::Base
  belongs_to :user
  has_many :users_lectures
  has_many :users, :through => :users_lectures, :dependent => :destroy
end

class UsersLecture < ActiveRecord::Base
  belongs_to :user
  belongs_to :lecture
end

class Friendship < ActiveRecord::Base
  belongs_to :user
  belongs_to :friend, class_name: 'User', foreign_key: 'friend_id'
end
