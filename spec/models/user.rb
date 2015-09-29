class User < ActiveRecord::Base
  attr_cached :name, :key, :desc, by: :last_activity, expires_in: 5.minutes, cache_provider: CacheProvider.new, set_time: true

  def desc=(s)
    self.desc_cached = s
    super(s)
  end

  # Define attr_accessible
  if ActiveRecord::VERSION::MAJOR == 3
    attr_accessible :lat, :last_activity, :name, :key, :desc
  end
end
