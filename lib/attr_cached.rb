require 'active_record' unless defined?(ActiveRecord)

# Add cache methods and overrides save(!)
module AttrCached
  # Override default save methods to control cache
  def save!(opts = {})
    save_cache_store! # Always save cache store!
    super(opts) if opts[:force] == true || write_cache_to_db?
  end

  def save(opts = {})
    save_cache_store! # Always save cache store!
    super(opts) if opts[:force] == true || write_cache_to_db?
  end

  def set_attr_cached_values
    # Don't associate from an emtpy cache
    if attr_cache_store.keys.count > 0
      attr_cached_attributes.each do |attribute|
        # Call _changed on each attributes
        self[attribute] = attr_cache_store[attribute]
      end
    end

    # Set default time after initialize
    send("#{attr_cached_by}=", self.class.default_timezone == :utc ? Time.now.utc : Time.now) if set_attr_cached_time
  end
  private :set_attr_cached_values

  # Decide if it is required to write cache content to database.
  def write_cache_to_db?
    # Last written cache_time!
    last_db_update = send("#{attr_cached_by}_was")

    # Compare
    # - last db update is nil!
    # - DB record expired
    # - other columns than specified was changed... (use ActiveModel::Dirty)
    last_db_update.nil? || (last_db_update + attr_cached_expires_in) < self[attr_cached_by] ||
      ((changed.map(&:to_sym) - attr_cached_attributes).count > 0)
  end

  def attr_cache_store
    @attr_cache_store ||= begin
      cache_data = cache_provider.read([self, :attr_cache_store]) || {}

      if cache_data[attr_cached_by] && self[attr_cached_by] && cache_data[attr_cached_by] > self[attr_cached_by]
        cache_data
      else
        {}
      end
    end
  end
  private :set_attr_cached_values

  def save_cache_store!
    cache_provider.write([self, :attr_cache_store], attr_cache_store)
  end
end

class ActiveRecord::Base
  # AttrCached active record method, required are +attribute+ and +by+, default value for expiration
  # is 5.minutes.
  #
  #   class Device < ActiveRecord::Base
  #     attr_cached :last_activity, by: :last_activity, cache_provider: CustomCacheProvider.cache
  #   end
  #
  #   +Attributes:+
  #   * +by+ - datetime column
  #   * +expires_in+ - invalidate DB record
  #   * +cache_provider+ - cache provider (default Rails.cache)
  #   * +set_time+ - set time to +by+ column after record intialize (default false, last activity from DB / cache is used)
  #
  def self.attr_cached(*args)
    # Extract options from args!
    opts = args.extract_options!

    # Check presence of *by*
    # TODO: data types!
    fail 'Attr_cached requires by attribute and it has to be a datetime attribute' unless opts[:by]

    # Set default provider
    opts[:cache_provider] ||= Rails.cache if defined?(Rails)

    # Check cache provider
    fail 'Attr_cached requires cache provider!' unless opts[:cache_provider]

    # Prepare fields
    args = (args << opts[:by]).compact.uniq.map(&:to_sym)

    # Set default expires_in
    opts[:expires_in] = 5.minutes

    # Include class methods
    include AttrCached
    class_attribute :attr_cached_attributes,
      :attr_cached_by,
      :attr_cached_expires_in,
      :cache_provider,
      :set_attr_cached_time

    # Add after initialize callback to set default values
    after_initialize :set_attr_cached_values

    # Set values to class
    self.attr_cached_attributes = args
    self.attr_cached_by         = opts[:by]
    self.attr_cached_expires_in = opts[:expires_in]
    self.cache_provider         = opts[:cache_provider]
    self.set_attr_cached_time   = opts[:set_time] || false

    # Redefine getters and setters!
    args.each do |attribute|
      define_method("#{attribute}=") do |val|
        attr_cache_store[attribute] = val
        super(val)
      end
    end
  end

  def set_attr_cached_time
    self.class.set_attr_cached_time
  end

  def cache_provider
    self.class.cache_provider
  end

  def attr_cached_attributes
    self.class.attr_cached_attributes
  end

  def attr_cached_by
    self.class.attr_cached_by
  end

  def attr_cached_expires_in
    self.class.attr_cached_expires_in
  end
end
