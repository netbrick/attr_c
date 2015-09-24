# Example class
class Device < ActiveRecord::Base
  attr_cached :lat, :lon, by: :last_activity, expires_in: 5.minutes, cache_provider: CacheProvider.new
end

