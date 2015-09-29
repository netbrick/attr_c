require 'active_record' unless defined?(ActiveRecord)

# Add cache methods and overrides save(!)
module AttrCached
  # Instance attribute to force-save record!
  attr_accessor :cache_force_save

  # Reset cache to original values!
  def reset_cache!
    attr_cached_attributes.each do |attribute|
      self[attribute] = send("#{attribute}_was")
    end
  end

  # Arround callback set original values (to dont save object)
  def attr_cached_values_save
    # Save cache store (always)
    save_cache_store!

    # Set original values?
    cached_attributes = {}

    # Write into DB?
    unless (@write_cache_to_db = write_cache_to_db?)
      # Clone old attributes
      cached_attributes = attr_cache_store.dup

      # Set old attributes
      reset_cache!
    end

    # Yield save (will not save the record if !write_cache_to_db?)
    yield

    # Set objects back to cache & AR attribute values
    return if write_cache_to_db?

    # Reassign attributes from cache
    attr_cached_attributes.each do |attribute|
      send("#{attribute}=", cached_attributes[attribute])
    end
  end
  private :attr_cached_values_save

  def set_attr_cached_values
    # Don't associate from an emtpy cache
    if attr_cache_store.keys.count > 0
      attr_cached_attributes.each do |attribute|
        # Will call _changed on attributes
        self[attribute] = attr_cache_store[attribute]
      end
    end

    # Set default time after initialize
    send("#{attr_cached_by}=", self.class.default_timezone == :utc ? Time.now.utc : Time.now) if attr_cached_time_set
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
      ((changed.map(&:to_sym) - attr_cached_attributes).count > 0) || cache_force_save
  end
  private :write_cache_to_db?

  def attr_cache_store
    @attr_cache_store ||= begin
      cache_data = attr_cached_provider.read([self, :attr_cache_store]) || {}

      if cache_data[attr_cached_by] && self[attr_cached_by] && cache_data[attr_cached_by] >= self[attr_cached_by]
        cache_data
      else
        # Set current values...
        attr_cached_attributes.each do |attribute|
          cache_data[attribute] = self[attribute]
        end

        # Return cached data
        cache_data
      end
    end
  end
  private :set_attr_cached_values

  def save_cache_store!
    attr_cached_provider.write([self, :attr_cache_store], attr_cache_store)
  end
  private :save_cache_store!
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
      :attr_cached_provider,
      :attr_cached_time_set

    # Add after initialize callback to set default values
    after_initialize :set_attr_cached_values

    # Around save callback (save, not save values)
    around_save :attr_cached_values_save
    # alias_method_chain :changes_applied, :cache

    # Set values to class
    self.attr_cached_attributes = args
    self.attr_cached_by         = opts[:by]
    self.attr_cached_expires_in = opts[:expires_in]
    self.attr_cached_provider   = opts[:cache_provider]
    self.attr_cached_time_set   = opts[:set_time] || false

    # Redefine getters and setters!
    args.each do |attribute|
      define_method("#{attribute}=") do |val|
        attr_cache_store[attribute] = val
        super(val)
      end

      define_method("#{attribute}_cached=") do |val|
        attr_cache_store[attribute] = val
      end
    end
  end

  def attr_cached_time_set
    self.class.attr_cached_time_set
  end

  def attr_cached_provider
    self.class.attr_cached_provider
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
