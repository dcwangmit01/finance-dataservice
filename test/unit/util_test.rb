require 'test_helper'
require 'dataservice/util'
require 'dataservice/google'

class UtilTest < ActiveSupport::TestCase

  test "ETime.new()" do
    et= Util::ETime.now()
    logger.info(et.to_yaml())
  end

  test "MarketTime" do

    # Sunday
    t = Util::ETime::From8601Str("2012-03-18T01:00:00-04:00")
    logger.info(t.to8601Str())

    # Monday
    t = Util::ETime::From8601Str("2012-03-18T12:15:00-04:00")
    assert(Util::MarketTime::BeforeHourMin?(t,  0,  0) == false, "time=[#{t.to8601Str()}] time.hour=[#{t.hour}] time.min=[#{t.min}]")
    assert(Util::MarketTime::BeforeHourMin?(t,  0, 30) == false, "time=[#{t.to8601Str()}] time.hour=[#{t.hour}] time.min=[#{t.min}]")
    assert(Util::MarketTime::BeforeHourMin?(t, 11,  0) == false, "time=[#{t.to8601Str()}] time.hour=[#{t.hour}] time.min=[#{t.min}]")
    assert(Util::MarketTime::BeforeHourMin?(t, 11, 30) == false, "time=[#{t.to8601Str()}] time.hour=[#{t.hour}] time.min=[#{t.min}]")
    assert(Util::MarketTime::BeforeHourMin?(t, 12, 15) == false,  "time=[#{t.to8601Str()}] time.hour=[#{t.hour}] time.min=[#{t.min}]")
    assert(Util::MarketTime::BeforeHourMin?(t, 12, 30) == true,  "time=[#{t.to8601Str()}] time.hour=[#{t.hour}] time.min=[#{t.min}]")
    assert(Util::MarketTime::BeforeHourMin?(t, 13, 00) == true,  "time=[#{t.to8601Str()}] time.hour=[#{t.hour}] time.min=[#{t.min}]")
    assert(Util::MarketTime::BeforeHourMin?(t, 23, 59) == true,  "time=[#{t.to8601Str()}] time.hour=[#{t.hour}] time.min=[#{t.min}]")

    assert(Util::MarketTime::AfterHourMin?(t,  0,   0) == true,  "time=[#{t.to8601Str()}] time.hour=[#{t.hour}] time.min=[#{t.min}]")
    assert(Util::MarketTime::AfterHourMin?(t,  0,  30) == true,  "time=[#{t.to8601Str()}] time.hour=[#{t.hour}] time.min=[#{t.min}]")
    assert(Util::MarketTime::AfterHourMin?(t,  12, 15) == false, "time=[#{t.to8601Str()}] time.hour=[#{t.hour}] time.min=[#{t.min}]")
    assert(Util::MarketTime::AfterHourMin?(t,  12, 30) == false, "time=[#{t.to8601Str()}] time.hour=[#{t.hour}] time.min=[#{t.min}]")
    assert(Util::MarketTime::AfterHourMin?(t,  13, 00) == false, "time=[#{t.to8601Str()}] time.hour=[#{t.hour}] time.min=[#{t.min}]")
    assert(Util::MarketTime::AfterHourMin?(t,  13, 30) == false, "time=[#{t.to8601Str()}] time.hour=[#{t.hour}] time.min=[#{t.min}]")
    assert(Util::MarketTime::AfterHourMin?(t,  23, 59) == false, "time=[#{t.to8601Str()}] time.hour=[#{t.hour}] time.min=[#{t.min}]")


    logger.info(t.to8601Str())


  end
end
