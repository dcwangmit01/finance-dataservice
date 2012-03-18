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

    # Create some variables used by the calculations
    lmd = Google::MarketDate::GetLastMarketDate()        
    now = Util::ETime.new()
    expirations = Option::GetExpirations(name)
    if (expirations.length == 0)
      logger.info("No Options found for name=[#{name}]")
      return
    end
    
    # figure out if and why we need to update the historical data,
    # and set variables msg and dirty

    expirations.each do |expiration|
      logger.info(expiration.to_yaml())
      r = Option::GetLastRecord(name, expiration)
      
      if (r == nil)
        # we need to update
      else
        dateoflast = Util::ETime::FromDate(r.date)
        if (dateoflast.dateEqual?(lmd))
          # update already happened
        else
          # we need to update
        end
      end

        
    end
      

  end

end
