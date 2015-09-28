# Example class
class Device < ActiveRecord::Base
  attr_cached :lat, :lon, by: :last_activity, expires_in: 5.minutes, cache_provider: CacheProvider.new

  # Define attr_accessible
  if ActiveRecord::VERSION::MAJOR == 3
    attr_accessible :lat, :lon, :last_activity, :key, :name
  end
end
