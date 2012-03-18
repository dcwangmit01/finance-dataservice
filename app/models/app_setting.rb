require 'solid_assert'

class AppSetting < ActiveRecord::Base

  def AppSetting.Exists(key)
    assert(key.kind_of?(String))
    assert(key.length()>0)
    c = AppSetting.first(:conditions => { :key => key })
    return (c != nil)
  end

  def AppSetting.Get(key)
    assert(key.kind_of?(String))
    assert(key.length()>0)
    
    assert(AppSetting::Exists(key))
    c = AppSetting.first(:conditions => { :key => key })

    assert(c != nil)
    return c
  end

  def AppSetting.Set(key, value)
    assert(key.kind_of?(String))
    assert(key.length()>0)
    assert(value.kind_of?(String))
    assert(value.length()>=0)

    c = AppSetting.Get(key)
    c.value = value
    c.save()

    assert(c != nil)
    return c
  end


  def AppSetting.Create(key, value)
    assert(key.kind_of?(String))
    assert(key.length()>0)
    assert(value.kind_of?(String))
    assert(value.length()>=0)

    assert(!AppSetting::Exists(key))
    c = AppSetting.new()
    c.key = key
    c.value = value
    c.save()

    assert(c != nil)
    return c
  end

end
