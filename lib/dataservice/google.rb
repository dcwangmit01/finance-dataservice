require 'dataservice/util'

require 'rubygems'
require 'mechanize'
require 'log4r'
require 'csv'
require 'json'

module Google

  class MarketDate
    DATE    = 'MarketData.LastMarketDateTime.value'
    UPDATED = 'MarketData.LastMarketDateTime.updatedat'

    def MarketDate.GetLastMarketDate()
      
      begin # Prime a non-existent cache
        if (!Cache::Exists(DATE))
          logger.info("Priming LastMarketDate: key=[#{DATE}] does not exist")
          Cache.Create(DATE, Util::ETime::at(0).to8601Str())
        end
        if (!Cache::Exists(UPDATED))
          logger.info("Priming LastMarketDate: key=[#{UPDATED}] does not exist")
          Cache.Create(UPDATED, Util::ETime::at(0).to8601Str())
        end
      end

      # Create some variables used by the calculations
      now = Util::ETime.new()
      up = Util::ETime::From8601Str(Cache::Get(UPDATED).value)
      
      # figure out if and why we need to update the historical data,
      # and set variables msg and dirty
      msg = ""
      dirty = false
      begin 
        if (now.weekend?())
          if (!up.dateEqual?(now))
            msg = ("Updating LastMarketDate: " +
                   "weekend " +
                   "up=[#{up.to8601Str()}] ne now=[#{now.to8601Str()}]")
            dirty = true
          end
        elsif (now.weekday?())
          if (# if has not checked today
              !up.dateEqual?(now) &&
              # && the time is before market close grace time
              MarketTime::BeforeClose?(now) && !MarketTime::CloseGrace?(now))
            msg = ("Updating LastMarketDate: " +
                   "weekday before market close " +
                   "up=[#{up.to8601Str()}] now=[#{now.to8601Str()}]")
            dirty = true
          elsif (# if the time is now after market close grace time
                 MarketTime::AfterClose?(now) && !MarketTime::CloseGrace?(now) &&
                 # && the last time we checked is before market close
                 MarketTime::BeforeClose?(up))
            msg = ("Updating LastMarketDate: " +
                   "weekday after market close " +
                   "up=[#{up.to8601Str()}] now=[#{now.to8601Str()}]")
            dirty = true
          end
        end
      end

      prevLmd = Util::ETime::From8601Str(Cache::Get(DATE).value)
      if (!dirty)
        # If there is no updated needed, then return the previous
        # lastModifiedDate
        return prevLmd
      else
        newLmd = nil
        begin
          # Fetch the latest historical data from a common ticker, to
          # get the last date
          t = Google::GoogleTicker.new('C')
          # 8 days ago
          s = Util::ETime.now().cloneDiffSeconds(-8*60*60*24).toDateStr()
          # 1 day ago
          e = Util::ETime.now().cloneDiffSeconds(-1*60*60*24).toDateStr()
          sd = t.getHistoricalStockData(s, e)
          logger.info(sd.to_yaml())
          assert(sd != nil)
          assert(sd.length()>0)
          
          date = sd[-1][:date]
          assert(date.length()>0)
          logger.info(date)
          newLmd = Util::ETime::FromDateStr(date)
          logger.info(newLmd)
          logger.info(newLmd.class)
          assert(newLmd.kind_of?(Util::ETime))
        end

        # Set the fields in the database
        ActiveRecord::Base.transaction do
          Cache::Set(DATE,    newLmd.to8601Str())
          Cache::Set(UPDATED, now.to8601Str())
          logger.info("Updating LastMarketDate " +
                      "prevLmd=[#{prevLmd.to8601Str()}] " +
                      "newLmd=[#{newLmd.to8601Str()}]" +
                      "updated=[#{now.to8601Str()}]")
        end
        
        return newLmd
      end
    end

    def MarketDate.logger()
      return Rails.logger
    end
    
  end

 
  class MarketTime
    
    # Grace time means: before and after market hours where we do not
    # want to fetch data, allowing for data providers to settle
    TIMES = {
      # gb = gracetime before
      # ga = gracetime after
      :open_gb  => { :hour => 06, :min => 00 },
      :open     => { :hour => 06, :min => 30 },
      :open_ga  => { :hour => 07, :min => 00 },
      :close_gb => { :hour => 12, :min => 30 },
      :close    => { :hour => 13, :min => 00 },
      :close_ga => { :hour => 13, :min => 30 } }

    # Helpers
    def MarketTime.BeforeHourMin?(time, hour, min)
      assert(time.kind_of?(ETime))
      assert(hour.kind_of?(Integer))
      assert(min.kind_of?(Integer))
      return true if time.hour < hour
      return true if time.min  < min
      return false
    end

    def MarketTime.AfterHourMin?(time, hour, min)
      assert(time.kind_of?(ETime))
      assert(hour.kind_of?(Integer))
      assert(min.kind_of?(Integer))
      return true if time.hour > hour
      return true if time.min  > min
      return false
    end

    # MarketTime Queries
    def MarketTime.BetweenHourMin?(time, hour1, min1, hour2, min2)
      assert(time.kind_of?(ETime))
      assert(hour1.kind_of?(Integer))
      assert(min1.kind_of?(Integer))
      assert(hour2.kind_of?(Integer))
      assert(min2.kind_of?(Integer))
      return (MarketTime::AfterHourMin(time, hour1, min1) &&
              MarketTime::BeforeHourMin(time, hour2, min2))
    end
    
    def MarketTime.BeforeOpen?(time)
      assert(time.kind_of?(Util::ETime))
      return time.timeBeforeHourMin?(time,
                                     MarketTime::TIMES[:open][:hour],
                                     MarketTime::TIMES[:open][:min])
    end

    def MarketTime.AfterOpen?(time)
      assert(time.kind_of?(Util::ETime))
      return (!MarketTime::BeforeOpen())
    end

    def MarketTime.BeforeClose?(time)
      assert(time.kind_of?(Util::ETime))
      return time.timeBeforeHourMin?(time,
                                     MarketTime::TIMES[:close][:hour],
                                     MarketTime::TIMES[:close][:min])
    end

    def MarketTime.AfterClose?(time)
      assert(time.kind_of?(Util::ETime))
      return (!MarketTime::BeforeClose())
    end

    def MarketTime.Open?(time)
      assert(time.kind_of?(Util::ETime))
      return (!MarketTime::Close?(time))
    end

    def MarketTime.Close?(time)
      assert(time.kind_of?(Util::ETime))
      return (MarketTime::BeforeOpen?(time) || MarketTime::AfterClose?(time))
    end
    
    def MarketTime.OpenGrace?(time)
      assert(time.kind_of?(Util::ETime))
      return (time.timeBetweenHourMin?(time,
                                       MarketTime::TIMES[:open_gb][:hour],
                                       MarketTime::TIMES[:open_gb][:min],
                                       MarketTime::TIMES[:open_ga][:hour],
                                       MarketTime::TIMES[:open_ga][:min]))
    end
    
    def MarketTime.CloseGrace?(time)
      assert(time.kind_of?(Util::ETime))
      return (time.timeBetweenHourMin?(time,
                                       MarketTime::TIMES[:close_gb][:hour],
                                       MarketTime::TIMES[:close_gb][:min],
                                       MarketTime::TIMES[:close_ga][:hour],
                                       MarketTime::TIMES[:close_ga][:min]))
    end

    def MarketTime.Grace?(time)
      assert(time.kind_of?(Util::ETime))
      return (MarketTime::OpenGrace?(time) || MarketTime::CloseGrace?(time))
    end
    
  end


  class GoogleTicker

    # http://www.google.com/finance?q=akam
    STOCK_URI  = URI('http://www.google.com/finance')
    
    # http://www.google.com/finance/historical?q=AKAM \
    #   &startdate=20120201&enddate=20120210&output=csv
    HISTORICAL_STOCK_DATA_URI = URI('http://www.google.com/finance/historical')
    
    # http://www.google.com/finance/option_chain?q=akam
    # 
    # http://www.google.com/finance/option_chain? \
    #   q=akam&expd=17&expm=3&expy=2012&output=json
    CURRENT_OPTION_DATA_URI = URI('http://www.google.com/finance/option_chain')
    
    @@agent = Mechanize.new()
    @@agent.user_agent_alias = 'Mac Safari'

    def initialize(ticker)
      @ticker = ticker
    end
    
    def doesTickerExist()
      # 8 days ago
      s = Util::ETime.now().cloneDiffSeconds(-8*60*60*24).toDateStr()
      # 1 day ago
      e = Util::ETime.now().cloneDiffSeconds(-1*60*60*24).toDateStr()
      return (self.getHistoricalStockData(s, e) != nil)
    end
    
    # Returns Data Inclusive of Dates
    def getHistoricalStockData(startdate, enddate)
      params = {
        :q         => @ticker,
        :startdate => startdate,
        :enddate   => enddate,
        :output    => :csv
      }

      page = nil
      begin
        page = @@agent.get(HISTORICAL_STOCK_DATA_URI, params)
      rescue => e
        return nil
      end

      # Dates Look Like:
      #   1-Mar-11 1-Apr-11 2-May-11 1-Jun-11 1-Jul-11 1-Aug-11
      #   1-Sep-11 3-Oct-11 1-Nov-11 1-Dec-11 3-Jan-12 1-Feb-12
      #   1-Mar-12

      ret = []
      first = true
      CSV.parse(page.body) do |r|
        # Skip header row
        #   Date,Open,High,Low,Close,Volume
        if first == true
          first = false
          next
        end
        
        ret.push({ :date   => Date.parse(r[0]).strftime("%Y-%m-%d"),
                   :open   => Integer(r[1].to_f() * 100),
                   :high   => Integer(r[2].to_f() * 100),
                   :low    => Integer(r[3].to_f() * 100),
                   :close  => Integer(r[4].to_f() * 100),
                   :volume => Integer(r[5]) })
      end

      return ret.reverse()
    end
    
    # Returns list of all current active option dates
    def getOptionDates()
      params = {
        :q      => @ticker,
      }

      page = nil
      begin
        page = @@agent.get(CURRENT_OPTION_DATA_URI, params)
      rescue => e
        logger.error("Unable to find option dates for #{@ticker}")
        return nil
      end

      exp = page.body.scan(/^google.finance.data =.*expirations:(\[.*?\]).*$/)
        .pop().pop()
        .gsub(/(\w+):/, '"\1":') # convert to proper json
      
      ret = []
      for j in JSON.parse(exp)
        ret.push(Date.new(j['y'], j['m'], j['d']).strftime("%Y-%m-%d"))
      end
      return ret
    end
    
    # Returns option data for a particular date
    def getOptionData(dateStr)
      dateParts = dateStr.split('-')
      params = {
        :q      => @ticker,
        :expd   => dateParts[2],
        :expm   => dateParts[1],
        :expy   => dateParts[0],
        :output => :json
      }
      page = nil
      begin
        page = @@agent.get(CURRENT_OPTION_DATA_URI, params)
      rescue => e
        logger.error("Unable to find option data for #{@ticker}")
        return nil
      end
      
      ret = JSON.parse(page.body.gsub(/(\w+):/, '"\1":')) # convert to proper json
      return ret
    end

    def logger()
      return Rails.logger
    end
    
  end
  
end

COMMENT = <<END
calls:
puts:
- cid: '681345055999672'
  name: ''
  s: AKAM120317P00020000
  e: OPRA
  p: ! '-'
  c: ! '-'
  b: ! '-'
  a: '0.01'
  oi: '      0'
  vol: ! '-'
  strike: '20.00'
  expiry: Mar 17, 2012
- cid: '311136124377695'
  name: ''
  s: AKAM120317P00034000
  e: OPRA
  p: '0.48'
  cs: chg
  c: '+0.20'
  cp: '71.43'
  b: '0.47'
  a: '0.49'
  oi: '   1430'
  vol: '    226'
  strike: '34.00'
  expiry: Mar 17, 2012
END

