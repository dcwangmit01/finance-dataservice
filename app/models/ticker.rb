

require 'dataservice/util'
require 'dataservice/google'

class Ticker < ActiveRecord::Base

  
  def Ticker.UpdateAll()

    marketTimes = Google::MarketTime.new()
    marketTimes.update()
    logger.info(marketTimes.to_yaml())



    Ticker.all(:order => "name ASC", 
               :conditions => {
                 :ticker_type => 'stock'
               }).each do |t|
      # Update the time variables for each cycle, since each cycle
      # could take various amounts of time to push us into a different
      # market state.
      times.update()
      
      if (times.market_status != Google::MarketStatus::AFTER_CLOSE)
        logger.info("Stopping all data updates because of market status" +
                    "name=[#{t.name}] " +
                    "market_status=[#{times.market_status}]")
        return
      end
      
      # Get the latest historical record to see when it was last updated
      s = Stock.find(:last, :order => "date ASC", :conditions => { :name => t.name })
      if (s != nil) 
        dbTime = Util::ETime::FromDate(s.date)

        if (dbTime.dateEqual?(times.last_market_date))
          logger.info("Ticker name=[#{t.name}] is already up to date: " + 
                      "last_record=[#{dbTime.toDate()}] " + 
                      "last_market_date=[#{times.last_market_date.toDate()}]")
          next
        elsif (dbTime.dateBefore?(times.last_market_date))
          logger.info("Ticker name=[#{t.name}] needs update between dates: " + 
                      "last_record=[#{dbTime.toDate()}] " + 
                      "last_market_date=[#{times.last_market_date.toDate()}]")
          Stock::Update(name, dbTime, times.last_market_date)
          next
        elsif (dbTime.dateAfter?(times.last_market_date))
          logger.error("Ticker name=[#{t.name}] updated with a date later than last_market_date: " + 
                       "last_record=[#{dbTime.toDate()}] " + 
                       "last_market_date=[#{times.last_market_date.toDate()}]")
          next
        end
        
      else
        # Then there is not yet history for this stock
        start = Util::ETime.new(2005, 1, 1)
        logger.info("Ticker name=[#{t.name}] needs initial data fetch between dates: " + 
                    "start=[#{start.toDate()}] " + 
                    "last_market_date=[#{times.last_market_date.toDate()}]")
        Stock::Update(name, start, times.last_market_date)
      end

    end    
  end


  def Exists(name)
    ticker = Ticker.find_by_name(name)
    return (ticker != nil)
  end
  

  def logger()
    return Rails.logger
  end

end
