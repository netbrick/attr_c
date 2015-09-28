# Example class without cache to proper compare database data!
class Device < ActiveRecord::Base
  # Define attr_accessible
  if ActiveRecord::VERSION::MAJOR == 3
    attr_accessible :lat, :lon, :last_activity, :key, :name
  end
end
