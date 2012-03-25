require 'solid_assert'

class AppSetting < ActiveRecord::Base

  def AppSetting.Exists(name)
    assert(name.kind_of?(String))
    assert(name.length()>0)
    c = AppSetting.first(:conditions => { :name => name })
    return (c != nil)
  end

  def AppSetting.Get(name)
    assert(name.kind_of?(String))
    assert(name.length()>0)
    
    assert(AppSetting::Exists(name))
    c = AppSetting.first(:conditions => { :name => name })

    assert(c != nil)
    return c
  end

  def AppSetting.Set(name, value)
    assert(name.kind_of?(String))
    assert(name.length()>0)
    assert(value.kind_of?(String))
    assert(value.length()>=0)

    c = AppSetting.Get(name)
    c.value = value
    c.save()

    assert(c != nil)
    return c
  end


  def AppSetting.Create(name, value)
    assert(name.kind_of?(String))
    assert(name.length()>0)
    assert(value.kind_of?(String))
    assert(value.length()>=0)

    assert(!AppSetting::Exists(name))
    c = AppSetting.new()
    c.name = name
    c.value = value
    c.save()

    assert(c != nil)
    return c
  end

end
