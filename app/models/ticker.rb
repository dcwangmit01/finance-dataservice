

require 'dataservice/util'
require 'dataservice/google'

class Ticker < ActiveRecord::Base

  PRIME = {
    :year => 2012,
    :mon  => 2,
    :day  => 1
  }
  
  def Ticker.UpdateAll()
    
    Ticker.all(:order => "name ASC", 
               :conditions => { :ticker_type => 'stock'}).each do |t|
      
      # Figure out the next
      start = nil
      begin
        s = Stock::GetLastRecord(t.name)
        if (s == nil)
          # There is not yet history for this stock, so prime it.
          start = Util::ETime.new(PRIME{:year}, PRIME{:mon}, PRIME{:day})
          logger.info("Priming historical update for ticker: " +
                      "name=[#{t.name}]: " +
                      "start=[#{start.toDateStr()}]")
        else
          # History does exist
          start = Util::ETime::FromDate(s.date)
          logger.info("Found last historical update for ticker: " +
                      "name=[#{t.name}]: " +
                      "start=[#{start.toDateStr()}]")
        end
      end
      
      finish = Google::MarketDate::GetLastMarketDate()
      if (start.dateBefore?(finish))
        logger.info("Starting historical update for ticker: " +
                    "name=[#{t.name}]: " +
                    "start=[#{start.toDateStr()}] " +
                    "finish=[#{finish.toDateStr()}]")
        Stock::Update(name, start, finish)
      else
        logger.info("Skipping unnecessary historical update for ticker: " +
                    "name=[#{t.name}]: " +
                    "start=[#{start.toDateStr()}] " +
                    "finish=[#{finish.toDateStr()}]")
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
