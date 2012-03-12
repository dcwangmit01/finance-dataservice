

require 'dataservice/util'
require 'dataservice/google'

class Ticker < ActiveRecord::Base
  
  def Ticker.UpdateAll()
    times = Google::MarketTime.new()
    times.update()
    logger.info(times)
    logger.info(times.to_yaml())
    if (times.market_status != Google::MarketStatus::AFTER_CLOSE)
      # TODO: It is possible to optimize data fetching of all
      # *historical* data during all hours, but it's not worth the
      # complexity right now.  Then you have to worry about the
      # trading day immediatly before the last trading day, and I
      # don't know how to calculate that.
      logger.info("Skipping data update because market_status=[#{times.market_status}]")
      return
    end

    tickers = Ticker.all(:order => "name ASC", :conditions => { :ticker_type => 'stock' })
    tickers.each do |t|
      # Update the time variables for each cycle, since each cycle
      # could take various amounts of time to push us into a different
      # market state.
      times.update()
      
      if (times.market_status != MarketStatus::AFTER_CLOSE)
        logger.info("Stopping all data updates because of market status" +
                    "name=[#{t.name}] " +
                    "market_status=[#{times.market_status}]")
        return
      end
      
      # Get the latest historical record to see when it was last updated
      s = Stock.find(:last, :order => "date ASC", :conditions => { :name => t.name })
      if (s != nil) 
        dbTime = Util::ETime::FromDate(s.date)

        # Check if the history is up to date
        if (dbTime.dateEqual?(times.last_market_date))
          logger.info("Ticker name=[#{t.name}] is already up to date: " + 
                      "last_record=[#{dbTime.toDate()}] " + 
                      "last_market_date=[#{times.last_market_date.toDate()}]")
          next
        else
          logger.info("Ticker name=[#{t.name}] needs update between dates: " + 
                      "last_record=[#{dbTime.toDate()}] " + 
                      "last_market_date=[#{times.last_market_date.toDate()}]")
          Stock.update(dbTime, times.last_market_date)
        end

      else
        # Then there is not yet history for this stock
        startdate = a year ago
      end


    end    

  end
  

  
  def Ticker.EnsureExists(name)
    
  end


  def update()
    if self.ticker_type.intern() == :stock
      return self.updateStock()
    elsif self.ticker_type.intern() == :option
      return self.updateOption()
    else
      logger.fatal("Unexpected Type " + self.ticker_type)
      exit(-1)
    end
  end

  def updateStock()
    logger.info("Updating stock " + self.name)
    
  end
  
  def updateOption()
    logger.info("Updating option " + self.name)
  end



  def Exists(name)
    ticker = Ticker.find_by_name(name)
    return (ticker != nil)
  end
  

  def logger()
    return Rails.logger
  end

end
