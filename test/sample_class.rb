# frozen_string_literal: true

class SampleClass
  def self.outer
    User.all.each do |user|
      inner(user)
    end
  end

  def self.inner(user)
    user.posts.to_a
  end
end
