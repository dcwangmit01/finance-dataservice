require 'dataservice/util'
require 'dataservice/google'

class Stock < ActiveRecord::Base

  EXPIRATION_DAYS = 7
  PRIME = Util::ETime.new(2012, 2, 1)
  
  def Stock.GetLastRecord(name)
    assert(name.kind_of?(String))
    assert(name.length()>0)

    # Get the latest historical record to see when it was last updated
    s = Stock.find(:last, :order => "date ASC", :conditions => { :name => name })
    return s # nil is okay
  end

  def Stock.UpdateAll()
    logger.info("UpdateAll Starting")
    Ticker.all(:order => "name ASC", 
               :conditions => { :ticker_type => 'stock'}).each do |t|
      Stock::Update(t.name)
    end    
  end

  def Stock.Update(name)
    assert(name.kind_of?(String))
    assert(name.length()>0)

    logger.info("Stock.Update Starting "+
             "ticker=[#{name}])");

    # Figure out the next
    start = nil
    begin
      s = Stock::GetLastRecord(name)
      if (s == nil)
        # There is not yet history for this stock, so prime it.
        logger.debug(PRIME.to_yaml())
        
        start = PRIME
        logger.info("Priming historical update for ticker: " +
                    "name=[#{name}]: " +
                    "start=[#{start.toDateStr()}]")
      else
        # History does exist
        start = Util::ETime::FromDate(s.date)
        logger.info("Found last historical update for ticker: " +
                    "name=[#{name}]: " +
                    "start=[#{start.toDateStr()}]")
      end
    end
    
    stop = Google::MarketDate::GetLastMarketDate()
    if (start.dateBefore?(stop))
      logger.info("Starting historical update for ticker: " +
                  "name=[#{name}]: " +
                  "start=[#{start.toDateStr()}] " +
                  "stop=[#{stop.toDateStr()}]")
      assert(start.kind_of?(Util::ETime))
      assert(stop.kind_of?(Util::ETime))
      assert(!start.dateEqual?(stop))
      Stock::FetchAndLoad(name, start, stop)
    else
      logger.info("Skipping unnecessary historical update for ticker: " +
                  "name=[#{name}]: " +
                  "start=[#{start.toDateStr()}] " +
                  "stop=[#{stop.toDateStr()}]")
    end

  end

  
  def Stock.FetchAndLoad(name, start, stop)
    assert(name.kind_of?(String))
    assert(name.length()>0)
    assert(start.kind_of?(Util::ETime))
    assert(stop.kind_of?(Util::ETime))
    assert(!start.dateEqual?(stop))

    t = Google::GoogleTicker.new(name)
    
    sd = t.getHistoricalStockData(start, stop)
    assert(sd != nil)
    assert(sd.length()>0)

    for d in sd
      assert(d.has_key?(:name) && d.length()>0)
      assert(d.has_key?(:open))
      assert(d.has_key?(:high))
      assert(d.has_key?(:low))
      assert(d.has_key?(:close))
      assert(d.has_key?(:volume))
      assert(d.has_key?(:date) && d[:date].kind_of?(Util::ETime))

      s = Stock.new()
      assert(s != nil)
      s.name = d[:name]
      s.open = d[:open]
      s.high = d[:high]
      s.low = d[:low]
      s.close = d[:close]
      s.volume = d[:volume]
      s.date = d[:date].toDateStr()
      s.save()
    end
    
  end


  def Stock.CalculateStatusActiveDelistedUnknown(name)
    # A stock is
    #   'active' if:
    #   - A historical db record exists, and the latest is not expired
    #   - OR Google knows about it
    #   'delisted' if:
    #   - A historical db record exists, and the latest is expired
    #   - AND Google does not know about it.
    #   'unknown' if:
    #   - A historical db record does not exist
    #   - AND Google does not know about it.
    #   
    # returns 'active', 'delisted', or 'unknown'

    ret_db_exist   = nil
    ret_db_expired = nil
    ret_in_google  = nil
    ret_status     = nil

    # Check database history, by getting the last historical entry
    db = Stock.find(:last, :order => "date ASC", :conditions => { :name => name })
    
    # Do historical records exist?
    ret_db_exist = (s!=nil) ? true : false
    
    if (ret_db_exist == true)
      # Are the records Expired?
      ret_db_expired = ((db.date <=> Date.new().prev_day(EXPIRATION_DAYS)) == -1) ? true : false
      
      if (ret_db_expired == false)
        ret_status = :active
      else
        # Does Google know about this ticker?
        ret_in_google = (Google::GoogleTicker.new(name).doesTickerExist()==true) ? true : false
        ret_status = (ret_in_google == true) ? :active : :delisted
      end
    else
      # Does Google know about this ticker?
      ret_in_google = (Google::GoogleTicker.new(name).doesTickerExist()==true) ? true : false
      ret_status = (ret_in_google == true) ? :active : :unknown
    end
    
    logger.debug("status[#{ret_status}]: db_exist[#{ret_db_exist}] "+
                 "db_expired[#{ret_db_expired}] in_google[#{ret_in_google}]")
    return ret_status
  end

  def logger()
    return Rails.logger
  end

end
