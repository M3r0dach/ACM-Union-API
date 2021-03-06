module Likeable
  extend ActiveSupport::Concern

  included do

  end

  def redis_key
    "like:#{self.class.to_s}:#{self.id}"
  end

  def like_by!(user)
    return false if $redis.zrank(self.redis_key, user.id).present?
    $redis.zadd(self.redis_key, Time.now.to_i, user.id)
    self.like_times += 1
    self.save
  end

  def like_users
    user_ids = $redis.zrange(self.redis_key, 0, -1, with_scores: false)
    Rails.logger.debug("#{self.redis_key} => #{user_ids}")
    User.where(id: user_ids)
  end

end