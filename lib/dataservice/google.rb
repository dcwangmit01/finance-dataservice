require 'dataservice/util'

require 'rubygems'
require 'mechanize'
require 'log4r'
require 'csv'
require 'json'

module Google

  class MarketDate
    DATE    = 'Cache.MarketData.LastMarketDateTime.value'
    UPDATED = 'Cache.MarketData.LastMarketDateTime.updated'

    def MarketDate.GetLastMarketDate()
      
      begin # Prime a non-existent appSetting
        if (!AppSetting::Exists(DATE))
          logger.info("Priming LastMarketDate: key=[#{DATE}] does not exist")
          AppSetting.Create(DATE, Util::ETime::at(0).to8601Str())
        end
        if (!AppSetting::Exists(UPDATED))
          logger.info("Priming LastMarketDate: key=[#{UPDATED}] does not exist")
          AppSetting.Create(UPDATED, Util::ETime::at(0).to8601Str())
        end
      end

      # Create some variables used by the calculations
      now = Util::ETime.new()
      up = Util::ETime::From8601Str(AppSetting::Get(UPDATED).value)
      
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
              Util::MarketTime::BeforeClose?(now) && !Util::MarketTime::CloseGrace?(now))
            msg = ("Updating LastMarketDate: " +
                   "weekday before market close " +
                   "up=[#{up.to8601Str()}] now=[#{now.to8601Str()}]")
            dirty = true
          elsif (# if the time is now after market close grace time
                 Util::MarketTime::AfterClose?(now) && !Util::MarketTime::CloseGrace?(now) &&
                 # && the last time we checked is before market close
                 Util::MarketTime::BeforeClose?(up))
            msg = ("Updating LastMarketDate: " +
                   "weekday after market close " +
                   "up=[#{up.to8601Str()}] now=[#{now.to8601Str()}]")
            dirty = true
          end
        end
      end

      prevLmd = Util::ETime::From8601Str(AppSetting::Get(DATE).value)
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
          s = Util::ETime.now().cloneDiffSeconds(-8*60*60*24)
          # 1 day ago
          e = Util::ETime.now().cloneDiffSeconds(-1*60*60*24)
          sd = t.getHistoricalStockData(s, e)
          assert(sd != nil)
          assert(sd.length()>0)
          newLmd = sd.pop()[:date] # get last date
          assert(newLmd.kind_of?(Util::ETime))
        end
        
        # Set the fields in the database
        ActiveRecord::Base.transaction do
          AppSetting::Set(DATE,    newLmd.to8601Str())
          AppSetting::Set(UPDATED, now.to8601Str())
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
    
    @@agent = Util::EMechanize.new()
    @@agent.user_agent_alias = 'Mac Safari'

    def initialize(ticker)
      assert(ticker.kind_of?(String) || ticker.kind_of?(Symbol))
      assert(ticker.length()>0)
      @ticker = ticker
    end
    
    def doesTickerExist()
      # 8 days ago
      s = Util::ETime.now().cloneDiffSeconds(-8*60*60*24)
      # 1 day ago
      e = Util::ETime.now().cloneDiffSeconds(-1*60*60*24)
      return (self.getHistoricalStockData(s, e) != nil)
    end
    
    # Returns Data Inclusive of Dates
    def getHistoricalStockData(startdate, enddate)
      assert(startdate.kind_of?(Util::ETime))
      assert(enddate.kind_of?(Util::ETime))
      assert(startdate.dateBefore?(enddate))
      
      params = {
        :q         => @ticker,
        :startdate => startdate.toDateStr(),
        :enddate   => enddate.toDateStr(),
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
          assert(r.length()==6, "Expected CSV of exactly 6 items")
          first = false
          next
        end
        
        ret.push({ :name   => @ticker,
                   :open   => Integer(r[1].to_f() * 100),
                   :high   => Integer(r[2].to_f() * 100),
                   :low    => Integer(r[3].to_f() * 100),
                   :close  => Integer(r[4].to_f() * 100),
                   :volume => r[5].to_i(),
                   :date   => Util::ETime::FromDateStr(r[0]) })
      end
      return ret.reverse()
    end
    
    # Returns list of all current active option dates
    def getCurrentOptionDates()
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
        ret.push(Util::ETime.new(j['y'], j['m'], j['d']))
      end
      return ret
    end
    
    # Returns option data for a particular date
    def getCurrentOptionData(date)
      assert(date.kind_of?(Util::ETime))

      debug = false

      dateParts = date.toDateStr().split('-').map { |p| p.to_i() }
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
      
      ret = []
      begin
        json = JSON.parse(page.body.gsub(/(\w+):/, '"\1":')) # convert to proper json
        assert(json.has_key?('calls'))
        assert(json.has_key?('puts'))
        assert(json['puts'].length()>0)
        assert(json['calls'].length()>0)
        assert(json['puts'].length() == json['calls'].length())
        
        # puts:
        # - cid: '681345055999672'   # ?
        #   name: ''                 # ?
        #   s: AKAM120317P00020000   # :name
        #   e: OPRA                  # ?
        #   p: ! '-'                 # :price
        #   c: ! '-'                 # :change
        #   b: ! '-'                 # :bid
        #   a: '0.01'                # :ask
        #   oi: '      0'            # :interest
        #   vol: ! '-'               # :volume
        #   strike: '20.00'          # :strike
        #   expiry: Mar 17, 2012     # :expiration

        for type in ['calls', 'puts']
          for o in json[type]

            name = nil
            begin
              assert(o.has_key?('s'))
              name = o['s']
              assert(name != nil) 
              assert(name.length()>0)
            end
            
            underlying = nil
            begin
              underlying = @ticker
              assert(underlying != nil)
              assert(underlying.length()>0)
            end
            
            option_type = nil
            begin
              option_type = (type == 'puts') ? 'put' : 'call'
              assert(option_type.match(/(put|call)/))
            end

            expiration = nil
            begin
              assert(o.has_key?('expiry'))
              assert(o['expiry'].length()>0)
              expiration = Util::ETime::FromDateStr(o['expiry'])
              assert(expiration.kind_of?(Util::ETime))
            end

            strike = nil
            begin
              assert(o.has_key?('strike'))
              assert(o['strike'] != nil)
              strike = Integer(o['strike'].to_f() * 100)
              assert(strike > 0)
            end
            
            price = nil
            begin
              assert(o.has_key?('p'))
              debug &&("parsing price[#{o[:p]}]")
              price = (o['p'].match(/^-$/)) ? nil : Integer(o['p'].to_f() * 100)
              # nil is okay
            end

            change = nil
            begin
              assert(o.has_key?('c'))
              debug &&("parsing change[#{o[:c]}]")
              change = (o['c'].match(/^-$/)) ? nil : Integer(o['c'].to_f() * 100)
              # nil is okay
            end

            bid = nil
            begin
              assert(o.has_key?('b'))
              debug &&("parsing bid[#{o['b']}]")
              bid = (o['b'].match(/^-$/)) ? nil : Integer(o['b'].to_f() * 100)
              # nil is okay
            end

            ask = nil
            begin
              assert(o.has_key?('a'))
              debug &&("parsing ask[#{o['a']}]")
              ask = (o['a'].match(/^-$/)) ? nil : Integer(o['a'].to_f() * 100)
              # nil is okay
            end

            volume = nil
            begin
              assert(o.has_key?('vol'))
              debug &&("parsing volume[#{o['vol']}]")
              volume = (o['vol'].match(/^-$/)) ? nil : o['vol'].to_i()
              # nil is okay
            end

            interest = nil
            begin
              assert(o.has_key?('oi'))
              debug &&("parsing interest[#{o['oi']}]")
              interest = (o['oi'].match(/^-$/)) ? nil : o['oi'].to_i()
              # nil is okay
            end

            ret.push({ :name        => name,
                       :underlying  => underlying,
                       :option_type => option_type,
                       :expiration  => expiration,
                       :strike      => strike,
                       :price       => price,
                       :change      => change,
                       :bid         => bid,
                       :ask         => ask,
                       :volume      => volume,
                       :interest    => interest })
          end
        end
        
      end
      

      assert(ret != nil)
      return ret
    end
    
    def logger()
      return Rails.logger
    end
  end
  
end
