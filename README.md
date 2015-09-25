# Cached attributes in ActiveRecord

[![Build Status](https://travis-ci.org/netbrick/attr_cached.svg)](https://travis-ci.org/netbrick/attr_cached)

This gem allows to save specific attributes in cache and save it to DB after limited time.

```ruby
class Device < ActiveRecord::Base
  attr_cached :lat, :lon, by: :last_activity, expires_in: 5.minutes
end
```

This means that parameters **lat, lon, last_activity** are persisted in Rails.cache. When the Device record is loaded from DB, those parameters are loaded from cache (if last_activity in DB is lower than last_activity in cache)... If you call *save* on user record and only *lat, lon and last_activity* parameters were changed, the record will be stored in DB only if last_activity stored in DB are older than 5 minutes!

## Force save

If you really want from some reason write record to database and you've
changed only cached values, set **cache_force_save** on object to
**true**.

```ruby
device = Device.first
device.lat = 5
device.cache_force_save = true
device.save! # This will update records in database (and each next save
on this object too!)
```

## Instalation

```ruby
gem 'attr_cached', github: 'netbrick/attr_cached'
```
