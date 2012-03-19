require 'dataservice/util'
require 'dataservice/google'

class Option < ActiveRecord::Base

  def Option.GetExpirations(name)
    assert(name.kind_of?(String))
    assert(name.length()>0)
    
    value_key   = "Cache.Option.OptionsList.#{name}.expirations.value"
    updated_key = "Cache.Option.OptionsList.#{name}.expirations.updated"
    
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
      lmd = Google::MarketDate::GetLastMarketDate()
      
      if (updated.dateBefore?(lmd))
        # Then there is updating to do.
        t = Google::GoogleTicker.new(name)
        dates = t.getCurrentOptionDates()
        value = dates.map { |d| d.toDateStr() }.join(",")
        updated = now
        
        logger.info("Updating Expirations for name=[#{name}] value=[#{value}] updated=[#{updated}]")
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

  def Option.Update(name)
    assert(name.kind_of?(String))
    assert(name.length()>0)
    
    logger.info("Option.Update Starting "+
                "ticker=[#{name}])");

    expirations = Option::GetExpirations(name)
    if (expirations.length == 0)
      logger.info("No Options found for name=[#{name}]")
      return
    end

    # Create some variables used by the calculations
    now = Util::ETime.new()
    lmd = Google::MarketDate::GetLastMarketDate()        
    
    # Break out if it is not the right time to update
    #   Only update the options during non-trading times
    if (now.weekday?() && (MarketTime::Grace?(now) || MarketTime::Open?(now)))
      return
    end

    # If we get here, then there might be something to update

    msg = ""
    dirty = false
    begin

      for expiration in expirations
        logger.info(expiration.to_yaml())
        r = Option::GetLastRecord(name, expiration)
        
        if (r == nil)
          # we need to update
          Option::FetchAndLoad(name, expiration, lmd)
        else
          dateoflast = Util::ETime::FromDate(r.date)
          if (dateoflast.dateEqual?(lmd))
            # update already happened
          else
            Option::FetchAndLoad(name, expiration, lmd)
          end
        end
        
        
      end
      
    end

  end

  def Option::FetchAndLoad(name, expiration, date)
    assert(name.kind_of?(String))
    assert(name.length()>0)
    assert(expiration.kind_of?(Util::ETime))
    assert(date.kind_of?(Util::ETime))

    logger.info("Executing FetchAndLoad for " +
                "name=[#{name}] " +
                "expiration=[#{expiration}] " +
                "date=[#{date}]")
    
    gt = Google::GoogleTicker.new(name)
    data = gt.getCurrentOptionData(expiration)
    assert(data != nil)

    for d in data
      assert(d.has_key?(:name))
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
      o.name = d[:name]
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
