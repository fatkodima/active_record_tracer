# frozen_string_literal: true

require "active_record_tracer"
require "minitest/autorun"
require "active_record"

require_relative "sample_class"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

if ENV["VERBOSE"]
  ActiveRecord::Base.logger = ActiveSupport::Logger.new($stdout)
else
  ActiveRecord::Base.logger = ActiveSupport::Logger.new("debug.log", 1, 100.megabytes)
  ActiveRecord::Migration.verbose = false
end

ActiveRecord::Schema.define do
  create_table :users

  create_table :posts do |t|
    t.integer :user_id
  end
end

class User < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :user
end

user1 = User.create!
2.times { user1.posts.create! }

user2 = User.create!
3.times { user2.posts.create! }

_user3 = User.create!

# Keep only lines for this gem.
ActiveRecordTracer.backtrace_cleaner = lambda { |backtrace|
  backtrace.grep(/active_record_tracer\/(lib|test)\//)
}
