require 'test_helper'
require 'dataservice/google'

class GoogleTest < ActiveSupport::TestCase

  test "MarketDate.GetLastMarketDate" do
    time = Google::MarketDate::GetLastMarketDate()
    logger.info("Time\n" + time.to8601Str())
  end

  test "GoogleTicker.doesTickerExist" do

    # assert that a ticker does not exist
    t = Google::GoogleTicker.new(:azam)
    r = t.doesTickerExist()
    assert(t.doesTickerExist() == false, "ticker should not exist #{r}")

    # assert that a ticker does exist
    t = Google::GoogleTicker.new(:akam)
    assert(t.doesTickerExist() == true, "ticker should exist")

  end

  test "GoogleTicker.getHistoricalStockData" do

    t = Google::GoogleTicker.new(:akam)
    # 8 days ago
    s = Util::ETime.now().cloneDiffSeconds(-8*60*60*24)
    # 1 day ago
    e = Util::ETime.now().cloneDiffSeconds(-1*60*60*24)
    
    logger.info("Finding stock data for #{s} #{e}")

    sd = t.getHistoricalStockData(s, e)
    assert(sd != nil)
    assert(sd.length()>0)
    logger.info("Historical Stock Data\n" + sd.to_yaml())

    for d in sd
      assert(d.has_key?(:name) && d.length()>0)
      assert(d.has_key?(:open))
      assert(d.has_key?(:high))
      assert(d.has_key?(:low))
      assert(d.has_key?(:close))
      assert(d.has_key?(:volume))
      assert(d.has_key?(:date) && d[:date].kind_of?(Util::ETime))
    end

  end

  test "GoogleTicker.getOptionDates and GoogleTicker.getOptionData" do
    
    t = Google::GoogleTicker.new(:akam)

    dates = t.getCurrentOptionDates()
    assert(dates != nil)
    assert(dates.length()>0)
    logger.info("OptionDates\n" + dates.to_yaml())
    
    data = t.getCurrentOptionData(dates[0])
    assert(data != nil)
    logger.info("OptionData\n" + data.to_yaml())

    data.each do |ele|
      assert(ele.has_key?(:name))
      assert(ele.has_key?(:underlying))
      assert(ele.has_key?(:option_type))
      assert(ele.has_key?(:expire))
      assert(ele.has_key?(:strike))
      assert(ele.has_key?(:price))
      assert(ele.has_key?(:change))
      assert(ele.has_key?(:bid))
      assert(ele.has_key?(:ask))
      assert(ele.has_key?(:volume))
      assert(ele.has_key?(:interest))
    end
  end

end
