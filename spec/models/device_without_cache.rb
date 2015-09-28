# Example class without cache to proper compare database data!
class DeviceWithoutCache < ActiveRecord::Base
  self.table_name = 'devices'

  # Define attr_accessible
  if ActiveRecord::VERSION::MAJOR == 3
    attr_accessible :lat, :lon, :last_activity, :key, :name
  end
end
