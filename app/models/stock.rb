class Stock < ActiveRecord::Base

  EXPIRATION_DAYS = 7

  def Stock.GetLastUpdateDate(name)
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

  def Stock.EnsureExists(name)
    
  end

  def Option.GetLastRecordDate(name)

  end

  def logger()
    return Rails.logger
  end

end
