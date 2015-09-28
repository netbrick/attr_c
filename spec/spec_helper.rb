# Open AR connection
require 'active_record'
ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'

# Load and require schema!
load    'schema.rb'
require 'schema.rb'

# Require attr_cached
require 'attr_cached'

# Require helpers
require 'helpers/cache_provider'

# Require model
require 'models/device'
require 'models/cashed_device'
require 'models/user'

# Require timecop for time-freezing
require 'timecop'

# RSpec configuration
RSpec.configure do |config|
  config.order = :random
end
