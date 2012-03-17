require 'test_helper'
require 'dataservice/google'

class GoogleTest < ActiveSupport::TestCase

  test "MarketDate.GetLastMarketDate" do
    time = Google::MarketDate::GetLastMarketDate()
    logger.info(time.to_yaml())
    logger.info(time)
  end

  test "doesTickerExist" do

    # assert that a ticker does not exist
    t = Google::GoogleTicker.new(:azam)
    r = t.doesTickerExist()
    assert(t.doesTickerExist() == false, "ticker should not exist #{r}")

    # assert that a ticker does exist
    t = Google::GoogleTicker.new(:akam)
    assert(t.doesTickerExist() == true, "ticker should exist")

  end

  test "getHistoricalStockData" do

    t = Google::GoogleTicker.new(:akam)
    # 8 days ago
    s = Util::ETime.now().cloneDiffSeconds(-8*60*60*24).toDateStr()
    # 1 day ago
    e = Util::ETime.now().cloneDiffSeconds(-1*60*60*24).toDateStr()
    
    logger.info("Finding stock data for #{s} #{e}")
    sd = t.getHistoricalStockData(s, e)
    assert(sd != nil)
    
    logger.info(sd.to_yaml())
    
    for d in sd
      assert(d.has_key?(:date) && d[:date].length()==10)
      assert(d.has_key?(:open))
      assert(d.has_key?(:high))
      assert(d.has_key?(:low))
      assert(d.has_key?(:close))
      assert(d.has_key?(:volume))
    end

  end

  test "getOptionDates getOptionData" do
    
    t = Google::GoogleTicker.new(:akam)
    dates = t.getOptionDates()
    logger.info(dates.to_yaml())

    assert(dates.length()>0, "unable to find options")
    
    data = t.getOptionData(dates[0])

    logger.info(data.to_yaml())

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
