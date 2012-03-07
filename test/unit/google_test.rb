require 'test_helper'
require 'dataservice/google'

class GoogleTest < ActiveSupport::TestCase

  test "doesTickerExist" do
    return

    # assert that a ticker does not exist
    t = Google::GoogleTicker.new(:azam)
    r = t.doesTickerExist()
    assert(t.doesTickerExist() == false, "ticker should not exist #{r}")

    # assert that a ticker does exist
    t = Google::GoogleTicker.new(:akam)
    assert(t.doesTickerExist() == true, "ticker should exist")

  end

  test "getOptionDates getOptionData" do
    t = Google::GoogleTicker.new(:akam)
    dates = t.getOptionDates()
    assert(dates.length()>0, "unable to find options")
    
    data = t.getOptionData(dates[0]['y'], dates[0]['m'], dates[0]['d'])

    assert(data.has_key?('puts'))
    assert(data.has_key?('calls'))

    assert(data['puts'].length()>0)
    assert(data['calls'].length()>0)

    for type in ['puts', 'calls']
      for ele in data[type]
        assert(ele.has_key?('cid'))
        assert(ele.has_key?('name'))
        assert(ele.has_key?('s'))
        assert(ele.has_key?('e'))
        assert(ele.has_key?('p'))
        assert(ele.has_key?('c'))
        assert(ele.has_key?('b'))
        assert(ele.has_key?('a'))
        assert(ele.has_key?('oi'))
        assert(ele.has_key?('vol'))
        assert(ele.has_key?('strike'))
        assert(ele.has_key?('expiry'))
      end
    end
  end

end
