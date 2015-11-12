require 'spec_helper'

describe 'attr_cached' do
  let(:device) { CachedDevice.create! }
  let(:user) { User.create! }
  let(:provider) { CachedDevice.attr_cached_provider }
  let(:user_provider) { User.attr_cached_provider }

  it 'init device with empty cache' do
    expect(device.new_record?).to eq(false)
  end

  context 'test key specification' do
    it 'default key' do
      u = User.create!
      u.desc = "Abcd"
      u.last_activity = Time.now.advance(hours: 2)
      expect(user_provider).to receive(:write).with([u, :attr_cache_store], any_args)
      u.save!
    end

    it 'own key' do
      d = CachedDevice.create!
      d.lat = 20.3030
      d.lon = 21.3030
      d.last_activity = Time.now.advance(hours: 2)
      expect(provider).to receive(:write).with("device_#{d.id}", any_args)
      d.save!
    end
  end

  # TODO: This will not work, because of Rails issue
  # https://github.com/rails/rails/issues/21802
  it 'dont reset dirty model after not save' do
    u = user
    u.last_activity = Time.now
    u.name = 'name'
    u.save! # Will touch the DB

    # Set new name
    u.name = 'set_new_name'
    u.save!

    # Check old value (ActiveModel::Dirty)
    expect(u.name_was).to eq('name')
    expect(u.name).to eq('set_new_name')
  end

  it 'user last_activity time always with current time' do
    time = Time.now + 10.minutes
    Timecop.freeze(time)
    u = user
    expect(u.last_activity.utc.to_i).to eq(time.utc.to_i)
    Timecop.return
  end

  it 'test overriden setter' do
    desc     = 'description'
    desc_new = 'new description'

    # Create user and set desc
    u = user
    u.desc = desc
    u.last_activity = Time.now
    u.save!

    # Change desc and test agains cache!
    u.desc = desc_new
    u.last_activity = Time.now.advance(seconds: 3)
    u.save!

    # Load data from cache
    cache_data = user_provider.read([u, :attr_cache_store]) || {}

    # Compare with data
    expect(cache_data[:desc]).to eq(desc_new)
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
    cache_data = provider.read(device.attr_cached_key)

    # Compare with data
    expect(cache_data).to match({ lat: lat, lon: lon, last_activity: time })
  end

  it 'write all data into cache' do
    # Now time
    time = Time.now
    lat  = 10.302
    lon  = 10.305

    # Write data
    device.lat = lat
    device.lon = lon
    device.last_activity = time
    device.save!

    # Clear cache
    provider.clear!
    expect(provider.read(device.attr_cached_key)).to eq(nil)

    # Load device
    d = CachedDevice.find device.id
    expect(d.lat).to eq(lat)

    # Set just one value
    d.lat = 5.302

    # Compare cache values
    d.save!

    # Full cached data!
    expect(d.last_activity.utc.to_i).to eq(time.utc.to_i)

    # Compare cash hash data
    provider_hash = provider.read(device.attr_cached_key)
    expect(provider_hash[:lat]).to eq(5.302)
    expect(provider_hash[:lon]).to eq(10.305)
    expect(provider_hash[:last_activity].utc.to_i).to eq(time.utc.to_i)

    # Load device again
    d = CachedDevice.find device.id
    expect(d.lat).to eq(5.302)
    expect(d.lon).to eq(10.305)
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

    # Get last update
    last_update = d.updated_at

    # Now reload data and set different data!
    d = CachedDevice.find(d.id)
    d.lat = lat + 1
    d.lon = lon + 1
    d.last_activity = time + 3.seconds
    d.save! # This call will not touch the database

    # But check if arround callback set data back!
    expect(d.lat).to eq(lat + 1)
    expect(d.lon).to eq(lon + 1)

    # Compare updated at!
    d = CachedDevice.find(d.id)
    expect(d.updated_at.utc.to_i).to eq(last_update.utc.to_i)

    # Test if DB contains old data!
    raw_device = Device.find(d.id)
    expect(raw_device.lat).to eq(lat)
    expect(raw_device.lon).to eq(lon)
    expect(raw_device.last_activity.utc.to_i).to eq(time.utc.to_i)

    # But data will be the new ones!
    expect(d.lat).to eq(lat + 1)
    expect(d.lon).to eq(lon + 1)
    expect(d.last_activity.utc.to_i).to eq((time + 3.seconds).utc.to_i)
  end

  it 'test cache force store' do
    d = device

    # Write data
    time = Time.now
    lat  = 10.302
    lon  = 10.305

    d.lat = lat
    d.lon = lon
    d.last_activity = time
    d.save!

    # Modify lat / lon and force save!
    d.lat = lat + 1
    d.lon = lon + 1
    d.last_activity = time + 3.seconds
    d.cache_force_save = true
    d.save!

    # Check DB data
    data = ActiveRecord::Base.connection.execute("SELECT lat, lon, last_activity FROM devices WHERE id = #{d.id}").first
    expect(data['lat']).to eq(lat + 1)
    expect(data['lon']).to eq(lon + 1)
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
    d = CachedDevice.find(d.id)
    d.lat = lat + 1
    d.lon = lon + 1
    d.last_activity = time + 10.minutes
    d.save! # This call will touch the database, because is more than 5.minutes

    # Compare updated at!
    d = CachedDevice.find(d.id)
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
    d = CachedDevice.find(d.id)
    d.lat = lat + 1
    d.lon = lon + 1
    d.last_activity = time + 3.seconds
    d.name = 'test_name'
    d.save! # This call will touch the database because some other attributes was set

    # Compare updated at!
    d = CachedDevice.find(d.id)
    expect(d.updated_at.utc.to_i).to_not eq(last_update.utc.to_i)
    expect(d.updated_at.utc.to_i).to     eq((time + 10.minutes).utc.to_i)

    Timecop.return
  end
end
