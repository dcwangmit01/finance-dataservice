require 'dataservice/util'
require 'dataservice/finance'

class Option < ActiveRecord::Base

  def Option.GetLastRecord(underlying)
    assert(underlying.kind_of?(String) || underlying.kind_of?(Symbol))
    assert(underlying.length()>0)

    # Get the latest historical record to see when it was last updated
    s = Option.find(:last, :order => "date ASC", 
                    :conditions => { :underlying => underlying })
    return s # nil is okay
  end

  def Option.Update(symbol)
    assert(symbol.kind_of?(String) || symbol.kind_of?(Symbol))
    assert(symbol.length()>0)
    
    # Create some variables used by the calculations
    now = Util::ETime.new()
    lmd = Finance::MarketDate::GetLastHistoricalMarketDate()
    r = Option::GetLastRecord(symbol)

    logger.info("Option.Update Starting: "+
                "symbol=[#{symbol}] " +
                "lastrecorddate=["+((r==nil)? 'nil' : Util::ETime::FromDate(r.date).to8601Str())+"] " +
                "lmd=[#{lmd}] " +
                "now=[#{now.to8601Str()}] " +
                "weekday?=[#{now.weekday?()}] " +
                "grace?=[#{Util::MarketTime::Grace?(now)}] " +
                "open?=[#{Util::MarketTime::Open?(now)}] " +
                "opengrace?=[#{Util::MarketTime::OpenGrace?(now)}] " +
                "closegrace?=[#{Util::MarketTime::CloseGrace?(now)}] " +
                "")
    
    if (now.dateEqual?(lmd) && Util::MarketTime::AfterClose?(now))
      if (r == nil)
        logger.info("Loading first options data for option: " +
                    "symbol=[#{symbol}]: ")
        Option::FetchAndLoad(symbol, lmd)
        return
      end

      if (!lmd.dateEqual?(Util::ETime::FromDate(r.date)))
        logger.info("Loading daily options data for option: " +
                    "symbol=[#{symbol}]: ")
        Option::FetchAndLoad(symbol, lmd)
        return
      end
    end

    logger.info("Skipping update of option"+
                "symbol=[#{symbol}] " +
                "")
    return
  end    
     
  def Option::FetchAndLoad(symbol, date)
    assert(symbol.kind_of?(String) || symbol.kind_of?(Symbol))
    assert(symbol.length()>0)
    assert(date.kind_of?(Util::ETime))

    logger.info("Executing FetchAndLoad for " +
                "symbol=[#{symbol}] " +
                "date=[#{date}]")
    
    t = Finance::DEFAULT_DATA_DRIVER.new(symbol)
    data = t.getCurrentOptionData()

    if (data == nil)
      logger.error("No option data found for " +
                   "symbol=[#{symbol}] " +
                   "date=[#{date.to8601Str()}]")
      return
    end

    for d in data
      assert(d.has_key?(:symbol))
      assert(d.has_key?(:underlying))
      assert(d.has_key?(:option_type))
      assert(d.has_key?(:expiration))
      assert(d.has_key?(:strike))
      assert(d.has_key?(:price))
      assert(d.has_key?(:change))
      assert(d.has_key?(:bid))
      assert(d.has_key?(:ask))
      assert(d.has_key?(:volume))
      assert(d.has_key?(:interest))

      o = Option.new()
      assert(o != nil)
      o.symbol = d[:symbol]
      o.underlying = d[:underlying]
      o.option_type = d[:option_type]
      o.expiration = d[:expiration].toDate()
      o.strike = d[:strike]
      o.price = d[:price]
      o.change = d[:change]
      o.bid = d[:bid]
      o.ask = d[:ask]
      o.volume = d[:volume]
      o.interest = d[:interest]

      o.date = date.toDate()

      o.save()
      
    end

  end
end
