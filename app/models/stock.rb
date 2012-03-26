require 'dataservice/util'
require 'dataservice/finance'

class Stock < ActiveRecord::Base

  PRIME = Util::ETime.new(2001, 1, 1)
  
  def Stock.GetLastRecord(symbol)
    assert(symbol.kind_of?(String) || symbol.kind_of?(Symbol))
    assert(symbol.length()>0)

    # Get the latest historical record to see when it was last updated
    s = Stock.find(:last, :order => "date ASC", :conditions => { :symbol => symbol })
    return s # nil is okay
  end

  def Stock.UpdateAll()
    logger.info("UpdateAll Starting")
    Ticker.all(:order => "symbol ASC", 
               :conditions => { :symbol_type => 'stock'}).each do |t|
      Stock::Update(t.symbol)
    end    
  end

  def Stock.Update(symbol)
    assert(symbol.kind_of?(String) || symbol.kind_of?(Symbol))
    assert(symbol.length()>0)

    logger.info("Stock.Update Starting "+
                "symbol=[#{symbol}])");

    # Figure out the next
    start = nil
    begin
      s = Stock::GetLastRecord(symbol)
      if (s == nil)
        # There is not yet history for this stock, so prime it.
        logger.debug(PRIME.to_yaml())
        
        start = PRIME
        logger.info("Priming historical update for stock: " +
                    "symbol=[#{symbol}]: " +
                    "start=[#{start.toDateStr()}]")
      else
        # History does exist
        start = Util::ETime::FromDate(s.date)
        logger.info("Found last historical update for stock: " +
                    "symbol=[#{symbol}]: " +
                    "start=[#{start.toDateStr()}]")
      end
    end
    
    stop = Finance::MarketDate::GetLastMarketDate()
    if (start.dateBefore?(stop))
      logger.info("Starting historical update for stock: " +
                  "symbol=[#{symbol}]: " +
                  "start=[#{start.toDateStr()}] " +
                  "stop=[#{stop.toDateStr()}]")
      assert(start.kind_of?(Util::ETime))
      assert(stop.kind_of?(Util::ETime))
      assert(!start.dateEqual?(stop))
      Stock::FetchAndLoad(symbol, start, stop)
    else
      logger.info("Skipping unnecessary historical update for stock: " +
                  "symbol=[#{symbol}]: " +
                  "start=[#{start.toDateStr()}] " +
                  "stop=[#{stop.toDateStr()}]")
    end

  end

  
  def Stock.FetchAndLoad(symbol, start, stop)
    assert(symbol.kind_of?(String) || symbol.kind_of?(Symbol))
    assert(symbol.length()>0)
    assert(start.kind_of?(Util::ETime))
    assert(stop.kind_of?(Util::ETime))
    assert(!start.dateEqual?(stop))

    t = Finance::DEFAULT_DATA_DRIVER.new(symbol)
    
    sd = t.getHistoricalStockData(start, stop)
    assert(sd != nil)
    assert(sd.length()>0)

    for d in sd
      assert(d.has_key?(:symbol) && d.length()>0)
      assert(d.has_key?(:open))
      assert(d.has_key?(:high))
      assert(d.has_key?(:low))
      assert(d.has_key?(:close))
      assert(d.has_key?(:volume))
      assert(d.has_key?(:date) && d[:date].kind_of?(Util::ETime))

      s = Stock.new()
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
