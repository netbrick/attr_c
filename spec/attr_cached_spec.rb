require 'spec_helper'

describe 'attr_cached' do
  let(:device) { Device.create! }
  let(:user) { User.create! }
  let(:provider) { Device.cache_provider }

  it 'init device with empty cache' do
    expect(device.new_record?).to be(false)
  end

  it 'user last_activity time always with current time' do
    time = Time.now + 10.minutes
    Timecop.freeze(time)
    u = user
    expect(u.last_activity.utc.to_i).to eq(time.utc.to_i)
    Timecop.return
  end

  it 'write device data into cache' do
    # Now time
    time = Time.now
    lat  = 10.302
    lon  = 10.305

    # Write data
    device.lat = lat
    device.lon = lon
    device.last_activity = time
    device.save!

    # Load data from cache
    cache_data = provider.read([device, :attr_cache_store])

    # Compare with data
    expect(cache_data).to match({ lat: lat, lon: lon, last_activity: time })
  end

  it 'set data twice and compare updated_at and new values' do
    d = device

    # Write data
    time = Time.now
    lat  = 10.302
    lon  = 10.305

    d.lat = lat
    d.lon = lon
    d.last_activity = time
    d.save!

    last_update = d.updated_at

    # Now reload data and set different data!
    d = Device.find(d.id)
    d.lat = lat + 1
    d.lon = lon + 1
    d.last_activity = time + 3.seconds
    d.save! # This call will not touch the database

    # Compare updated at!
    d = Device.find(d.id)
    expect(d.updated_at.utc.to_i).to eq(last_update.utc.to_i)

    # But data will be new!
    expect(d.lat).to eq(lat + 1)
    expect(d.lon).to eq(lon + 1)
    expect(d.last_activity.utc.to_i).to eq((time + 3.seconds).utc.to_i)
  end

  it 'save data on next update after more than 5.minutes' do
    d = device

    # Write data
    time = Time.now
    lat  = 10.302
    lon  = 10.305

    d.lat = lat
    d.lon = lon
    d.last_activity = time
    d.save!

    last_update = d.updated_at

    # Mock datetime
    Timecop.freeze(time + 10.minutes)

    # Now reload data and set different data!
    d = Device.find(d.id)
    d.lat = lat + 1
    d.lon = lon + 1
    d.last_activity = time + 10.minutes
    d.save! # This call will touch the database, because is more than 5.minutes

    # Compare updated at!
    d = Device.find(d.id)
    expect(d.updated_at.utc.to_i).to_not eq(last_update.utc.to_i)
    expect(d.updated_at.utc.to_i).to     eq((time + 10.minutes).utc.to_i)

    Timecop.return
  end

  it 'set different data twice and compare updated_at and new values' do
    d = device

    # Write data
    time = Time.now
    lat  = 10.302
    lon  = 10.305

    d.lat = lat
    d.lon = lon
    d.last_activity = time
    d.save!

    last_update = d.updated_at

    # Mock datetime
    Timecop.freeze(time + 10.minutes)

    # Now reload data and set different data!
    d = Device.find(d.id)
    d.lat = lat + 1
    d.lon = lon + 1
    d.last_activity = time + 3.seconds
    d.name = 'test_name'
    d.save! # This call will touch the database because some other attributes was set

    # Compare updated at!
    d = Device.find(d.id)
    expect(d.updated_at.utc.to_i).to_not eq(last_update.utc.to_i)
    expect(d.updated_at.utc.to_i).to     eq((time + 10.minutes).utc.to_i)

    Timecop.return
  end
end
