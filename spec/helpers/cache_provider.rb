class CacheProvider
  def initialize
    @cache = {}
  end

  def write(key, value)
    @cache[key] = value
  end

  def read(key)
    @cache[key]
  end

  def clear!
    @cache = {}
  end
end
