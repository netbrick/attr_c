source 'https://rubygems.org'

if ENV['ACTIVERECORD_VERSION'] == 'master'
  gem 'rails', github: 'rails/rails'
else
  gem 'activerecord', "~> #{ENV['ACTIVERECORD_VERSION'] || '4.2.4'}"
end

group :development, :test do
  gem 'sqlite3', platforms: [:ruby]
  gem 'activerecord-jdbcsqlite3-adapter', platforms: [:jruby]
end

# Specify your gem's dependencies in attr_cached.gemspec
gemspec
