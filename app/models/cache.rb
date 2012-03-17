require 'solid_assert'

class Cache < ActiveRecord::Base

  def Cache.Exists(key)
    assert(key.kind_of?(String))
    assert(key.length()>0)
    c = Cache.first(:conditions => { :key => key })
    return (c != nil)
  end

  def Cache.Get(key)
    assert(key.kind_of?(String))
    assert(key.length()>0)
    
    assert(Cache::Exists(key))
    c = Cache.first(:conditions => { :key => key })

    assert(c != nil)
    return c
  end

  def Cache.Set(key, value)
    assert(key.kind_of?(String))
    assert(key.length()>0)
    assert(value.kind_of?(String))
    assert(value.length()>=0)

    c = Cache.Get(key)
    c.value = value
    c.save()

    assert(c != nil)
    return c
  end


  def Cache.Create(key, value)
    assert(key.kind_of?(String))
    assert(key.length()>0)
    assert(value.kind_of?(String))
    assert(value.length()>=0)

    assert(!Cache::Exists(key))
    c = Cache.new()
    c.key = key
    c.value = value
    c.save()

    assert(c != nil)
    return c
  end
  
end
