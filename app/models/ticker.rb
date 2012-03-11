
require 'dataservice/google'
require 'test/unit'

class Ticker < ActiveRecord::Base
  EXPIRATION_DAYS = 7

  
  
  def Ticker.UpdateAll()
    times = GoogleTicker::GetMarketTimes()
    
    if times[:marketStatus] == MarketStatus::OPEN
      logger.info("Market is currently open, Not pulling info")
      return
    end

    stocks = Ticker.all(:conditions => { :ticker_type => 'stock' })
    
    stocks.each do |t|
      # Get the latest Stock Object to see when it was last updated
      s = Stock.find(:last, :order => "date ASC", :conditions => { :name => name })
      

      # Dates
      #  Today
      #  LastUpdateOfStock
      #  LastMarketDay
      
      

      # after_market and not on the same day
      # after_market and on the same day
      # before_market and on the same day?
      # during_market
      
    end    

    logger.info(stocks.to_yaml())
    # Update only stocks, and from stocks recursively update options

    
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
