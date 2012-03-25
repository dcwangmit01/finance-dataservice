require 'test_helper'

class AppSettingTest < ActiveSupport::TestCase
  test "AppSetting" do
    name   = "test_name"
    value1 = "test_value1" 
    value2 = "test_value2" 
    
    assert(!AppSetting::Exists(name))

    AppSetting::Create(name, value1)
    assert(AppSetting::Exists(name))
    
    v = AppSetting::Get(name)
    assert(v = value1)

    AppSetting::Set(name, value2)
    assert(AppSetting::Exists(name))
    
    v = AppSetting::Get(name)
    assert(v = value2)
    
  end
end
