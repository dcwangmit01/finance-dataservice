require 'dataservice/util'
require 'dataservice/finance'

class Option < ActiveRecord::Base

  def Option.GetExpirations(symbol)
    assert(symbol.kind_of?(String) || symbol.kind_of?(Symbol))
    assert(symbol.length()>0)
    
    value_key   = "Cache.Option.OptionsList.#{symbol}.expirations.value"
    updated_key = "Cache.Option.OptionsList.#{symbol}.expirations.updated"
    
    begin # Prime a non-existent appSetting
      if (!AppSetting::Exists(value_key))
        logger.info("Priming Option.Expirations: key=[#{value_key}] does not exist")
        AppSetting.Create(value_key, "")
      end
      if (!AppSetting::Exists(updated_key))
        logger.info("Priming Option.Expirations: key=[#{updated_key}] does not exist")
        AppSetting.Create(updated_key, Util::ETime::at(0).to8601Str())
      end
    end
    
    # Update the DB cache if necessary
    begin
      # Create some variables used by the calculations
      now = Util::ETime.new()
      updated = Util::ETime::From8601Str(AppSetting::Get(updated_key).value)
      lmd = Finance::MarketDate::GetLastMarketDate()
      
      if (updated.dateBefore?(lmd))
        # Then there is updating to do.
        t = Google::GoogleTicker.new(symbol)
        dates = t.getCurrentOptionDates()
        value = dates.map { |d| d.toDateStr() }.join(",")
        updated = now
        
        logger.info("Updating Expirations for symbol=[#{symbol}] value=[#{value}] updated=[#{updated}]")
        AppSetting::Set(value_key, value)
        AppSetting::Set(updated_key, updated.to8601Str())
      end
    end

    # Return the values
    ret = AppSetting::Get(value_key).value.split(",").map { |s| Util::ETime::FromDateStr(s)}
    return ret
  end
  
  def Option.GetLastRecord(underlying, expiration)
    assert(underlying.kind_of?(String))
    assert(underlying.length()>0)
    assert(expiration.kind_of?(Util::ETime))

    # Get the latest historical record to see when it was last updated
    s = Option.find(:last, :order => "date ASC", 
                    :conditions => { :underlying => underlying, :expiration => expiration.toDate() })
    return s # nil is okay
  end

  def Option.Update(symbol)
    assert(symbol.kind_of?(String))
    assert(symbol.length()>0)
    
    logger.info("Option.Update Starting "+
                "symbol=[#{symbol}])");

    expirations = Option::GetExpirations(symbol)
    if (expirations.length == 0)
      logger.info("No Options found for symbol=[#{symbol}]")
      return
    end

    # Create some variables used by the calculations
    now = Util::ETime.new()
    lmd = Finance::MarketDate::GetLastMarketDate()        
    
    # Break out if it is not the right time to update
    #   Only update the options during non-trading times
    if (now.weekday?() && (Util::MarketTime::Grace?(now) || Util::MarketTime::Open?(now)))
      logger.info("Breaking out because it's not the right time to update "+
                  "now=[#{now.to8601Str()}] " +
                  "weekday?=[#{now.weekday?()}] " +
                  "grace?=[#{Util::MarketTime::Grace?(now)}] " +
                  "open?=[#{Util::MarketTime::Open?(now)}] " +
                  "opengrace?=[#{Util::MarketTime::OpenGrace?(now)}] " +
                  "closegrace?=[#{Util::MarketTime::CloseGrace?(now)}] " +
                  "")

      return
    end

    # If we get here, then there might be something to update

    msg = ""
    dirty = false
    begin

      for expiration in expirations
        logger.info(expiration.to_yaml())
        r = Option::GetLastRecord(symbol, expiration)
        
        if (r == nil)
          # we need to update
          Option::FetchAndLoad(symbol, expiration, lmd)
        else
          dateoflast = Util::ETime::FromDate(r.date)
          if (dateoflast.dateEqual?(lmd))
            # update already happened
          else
            Option::FetchAndLoad(symbol, expiration, lmd)
          end
        end
        
        
      end
      
    end

  end

  def Option::FetchAndLoad(symbol, expiration, date)
    assert(symbol.kind_of?(String))
    assert(symbol.length()>0)
    assert(expiration.kind_of?(Util::ETime))
    assert(date.kind_of?(Util::ETime))

    logger.info("Executing FetchAndLoad for " +
                "symbol=[#{symbol}] " +
                "expiration=[#{expiration}] " +
                "date=[#{date}]")
    
    gt = Google::GoogleTicker.new(symbol)
    data = gt.getCurrentOptionData(expiration)

    if (data == nil)
      logger.error("No option data found for " +
                "name=[#{name}] " +
                "expiration=[#{expiration.to8601Str()}] " +
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
