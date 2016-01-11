# Cached attributes in ActiveRecord

[![Build Status](https://travis-ci.org/netbrick/attr_cached.svg)](https://travis-ci.org/netbrick/attr_cached)

This gem allows to save specific attributes in cache and save it to DB after limited time.

```ruby
class Device < ActiveRecord::Base
  attr_cached :lat, :lon, by: :last_activity, expires_in: 5.minutes

  # Override setter (always call _cached method version!)
  def lat=(s)
    if s
      self.lat_cached = s
      super(s)
    end
  end
end
```

This means that parameters **lat, lon, last_activity** are persisted in Rails.cache. When the Device record is loaded from DB, those parameters are loaded from cache (if last_activity in DB is lower than last_activity in cache)... If you call *save* on user record and only *lat, lon and last_activity* parameters were changed, the record will be stored in DB only if last_activity stored in DB are older than 5 minutes!

### Known issues with older ActiveRecords

There is a problem in dirty checking currently open in Rails!
https://github.com/rails/rails/issues/21442
Please see the *dont reset dirty model after not save* test to avoid current issue. We hope it will be
fixed in new version of rails.

### Cache control

If you want to store your model data in other specified cache, you can
override **attr_cached_key** method in your model.

```ruby
class Device
  attr_cached :lat, :lon

  def attr_cached_key
    "device_#{id}"
  end
end
```

### Behaviour

```cmd
2.1.5 :010 > d = Device.find 1
  Device Load (2.2ms)  SELECT  "devices".* FROM "devices"   ORDER BY "devices"."id" DESC LIMIT 1
 => #<Device id: 1, user_id: 548, lat: nil, lng: nil, last_activity: nil, created_at: "2015-09-25 14:24:45", updated_at: "2015-09-28 15:40:25">
2.1.5 :012 > d.lng = 10.302
 => 10.302
2.1.5 :013 > d.last_activity = Time.zone.now
 => Mon, 28 Sep 2015 21:01:06 CEST +02:00
2.1.5 :014 > d.save! # This will touch the DB!
   (0.3ms)  BEGIN
  SQL (3.4ms)  UPDATE "devices" SET "last_activity" = $1, "lng" = $2, "updated_at" = $4 WHERE "devices"."id" = 1  [["last_activity", "2015-09-28 19:01:06.955555"], ["lng", 10.203], ["updated_at", "2015-09-28 19:02:40.173626"]]
   (0.5ms)  COMMIT
 => true
2.1.5 :015 > d = Device.find 1
  Device Load (2.2ms)  SELECT  "devices".* FROM "devices"   ORDER BY "devices"."id" DESC LIMIT 1
 => #<Device id: 1, user_id: 548, lat: nil, lng: 10.2013, last_activity:  "2015-09-28 19:01:06.955555", created_at: "2015-09-25 14:24:45", updated_at: "2015-09-28 19:02:40.173626">
2.1.5 :016 > d.lat = 15.203
 => 15.203
2.1.5 :017 > d.last_activity = Time.zone.now.advance(seconds: 5)
 => Mon, 28 Sep 2015 21:04:42 CEST +02:00
2.1.5 :017 > d.save! # This will not!
   (0.3ms)  BEGIN
   (0.2ms)  COMMIT
 => true
2.1.5 :015 > d = Device.find 1
  Device Load (2.2ms)  SELECT  "devices".* FROM "devices"   ORDER BY "devices"."id" DESC LIMIT 1
 => #<Device id: 1, user_id: 548, lat: nil, lng: 10.2013, last_activity:  "2015-09-28 19:01:06.955555", created_at: "2015-09-25 14:24:45", updated_at: "2015-09-28 19:02:40.173626">
2.1.5 :016 > d.lat
=> 15.203
2.1.5 :017 > d.lat = 12.203
 => 12.203
2.1.5 :018 > d.last_activity = Time.zone.now.advance(minutes: 10)
 => Mon, 28 Sep 2015 21:14:42 CEST +02:00
2.1.5 :020 > d.save! # This will
   (0.3ms)  BEGIN
  SQL (3.4ms)  UPDATE "devices" SET "last_activity" = $1, "lng" = $2, "updated_at" = $4 WHERE "devices"."id" = 1  [["last_activity", "2015-09-28 19:14:42.952355"], ["lng", 12.203], ["updated_at", "2015-09-28 19:10:20.174329"]]
   (0.5ms)  COMMIT
 => true
```

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
