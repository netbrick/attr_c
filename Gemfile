source 'https://rubygems.org'

gem 'activerecord', "~> #{ENV['ACTIVERECORD_VERSION'] || '4.2.4'}"

group :development, :test do
  gem 'sqlite3', platforms: [:ruby]
  gem 'activerecord-jdbcsqlite3-adapter', platforms: [:jruby]
end

# Specify your gem's dependencies in attr_cached.gemspec
gemspec
