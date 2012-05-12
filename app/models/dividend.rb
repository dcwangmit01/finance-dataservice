require 'dataservice/util'
require 'dataservice/finance'

class Dividend < ActiveRecord::Base

  PRIME = Util::ETime.new(2001, 1, 1)
  
  def Dividend.GetLastRecord(symbol)
    assert(symbol.kind_of?(String) || symbol.kind_of?(Symbol))
    assert(symbol.length()>0)

    # Get the latest historical record to see when it was last updated
    s = Dividend.find(:last, :order => "date ASC", :conditions => { :symbol => symbol })
    return s # nil is okay
  end

  def Dividend.UpdateAll()
    logger.info("UpdateAll Starting")
    Ticker.all(:order => "symbol ASC", 
               :conditions => { :symbol_type => 'dividend'}).each do |t|
      Dividend::Update(t.symbol)
    end    
  end

  def Dividend.Update(symbol)
    assert(symbol.kind_of?(String) || symbol.kind_of?(Symbol))
    assert(symbol.length()>0)

    logger.info("Dividend.Update Starting "+
                "symbol=[#{symbol}])");

    # Figure out the next
    start = nil
    begin
      s = Dividend::GetLastRecord(symbol)
      if (s == nil)
        # There is not yet history for this dividend, so prime it.
        logger.debug(PRIME.to_yaml())
        
        start = PRIME
        logger.info("Priming historical update for dividend: " +
                    "symbol=[#{symbol}]: " +
                    "lastRecordDate=[nil] " + 
                    "start=[#{start.toDateStr()}]")
      else
        # History does exist
        start = Util::ETime::FromDate(s.date+1)
        logger.info("Found last historical update for dividend: " +
                    "symbol=[#{symbol}]: " +
                    "start=[#{start.toDateStr()}]")
      end
    end
    
    stop = Finance::MarketDate::GetLastHistoricalMarketDate()
    if (start.dateBefore?(stop))
      logger.info("Starting historical update for dividend: " +
                  "symbol=[#{symbol}]: " +
                  "start=[#{start.toDateStr()}] " +
                  "stop=[#{stop.toDateStr()}]")
      assert(start.kind_of?(Util::ETime))
      assert(stop.kind_of?(Util::ETime))
      assert(!start.dateEqual?(stop))
      Dividend::FetchAndLoad(symbol, start, stop)
    else
      logger.info("Skipping unnecessary historical update for dividend: " +
                  "symbol=[#{symbol}]: " +
                  "start=[#{start.toDateStr()}] " +
                  "stop=[#{stop.toDateStr()}]")
    end

  end

  
  def Dividend.FetchAndLoad(symbol, start, stop)
    assert(symbol.kind_of?(String) || symbol.kind_of?(Symbol))
    assert(symbol.length()>0)
    assert(start.kind_of?(Util::ETime))
    assert(stop.kind_of?(Util::ETime))
    assert(!start.dateEqual?(stop))

    t = Finance::DEFAULT_DATA_DRIVER.new(symbol)
    
    sd = t.getHistoricalDividendAndSplitData(start, stop)
    assert(sd != nil)
    assert(sd.length()>0)
    assert(sd.has_key?(:dividends))
    assert(sd.has_key?(:splits))

    for d in sd[:dividends]
      
    end

    for d in sd
      assert(d.has_key?(:symbol) && d.length()>0)
      assert(d.has_key?(:open))
      assert(d.has_key?(:high))
      assert(d.has_key?(:low))
      assert(d.has_key?(:close))
      assert(d.has_key?(:volume))
      assert(d.has_key?(:date) && d[:date].kind_of?(Util::ETime))

      s = Dividend.new()
      assert(s != nil)
      s.symbol  = d[:symbol]
      s.open    = d[:open]
      s.high    = d[:high]
      s.low     = d[:low]
      s.close   = d[:close]
      s.volume  = d[:volume]
      s.date    = d[:date].toDateStr()
      s.save()
    end
    
  end

  def logger()
    return Rails.logger
  end


end
