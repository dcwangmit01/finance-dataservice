require 'dataservice/util'

require 'rubygems'
require 'mechanize'
require 'log4r'
require 'csv'
require 'json'
require 'solid_assert'

module Finance

  class TickerDataInterface
    
    @@agent = Util::EMechanize.new()
    @@agent.user_agent_alias = 'Mac Safari'

    def initialize(symbol)
      assert(symbol.kind_of?(String) || symbol.kind_of?(Symbol))
      assert(symbol.length()>0)
      @symbol = symbol
    end

    def doesTickerExist()
      # From 8 days ago to 1 day ago
      s = Util::ETime.now().cloneDiffSeconds(-8*60*60*24)
      e = Util::ETime.now().cloneDiffSeconds(-1*60*60*24)
      return (self.getHistoricalStockData(s, e) != nil)
    end

    def getHistoricalStockData(startdate, enddate)
      # Returns Data Inclusive of Dates
      assert(false, "This method must be overridden")
    end

    def getHistoricalDividendAndSplitData(startdate, enddate)
      assert(false, "This method must be overridden")
    end

    def getCurrentOptionData()
      assert(false, "This method must be overridden")
    end

    def logger()
      return Rails.logger
    end
    
  end

  class YahooTicker < TickerDataInterface
    
    def getHistoricalStockData(startdate, enddate)
      # Inclusive Date Ranges
      # http://ichart.finance.yahoo.com/table.csv? \
      #   s=AKAM&a=01&b=6&c=2004&d=03&e=7&f=2012&g=d&ignore=.csv
      # Feb 6 2004 to Apr 7 2012
      # http://ichart.finance.yahoo.com/table.csv
      #   ?s=AKAM (stock ticker)
      #   &a=01	(start month from 0)
      #   &b=6	(start date from 1)
      #   &c=2004 (start year)
      #   &d=03   (end month from 0)
      #   &e=7    (end date from 1)
      #   &f=2012 (end year)
      #   &g=d
      #   &ignore=.csv
      assert(startdate.kind_of?(Util::ETime))
      assert(enddate.kind_of?(Util::ETime))
      assert(startdate.dateBefore?(enddate))
      
      startParts = startdate.toDateStr().split('-').map { |p| p.to_i() } # DateStr = YYYYMMDD
      endParts = enddate.toDateStr().split('-').map { |p| p.to_i() }
      params = {
        :s => @symbol,
        :a => startParts[1]-1,
        :b => startParts[2],
        :c => startParts[0],
        :d => endParts[1]-1,
        :e => endParts[2],
        :f => endParts[0],
        :g => :d,
        :ignore => '.csv'
      }
      uri = 'http://ichart.finance.yahoo.com/table.csv'

      page = nil
      begin
        page = @@agent.get(uri, params)
      rescue => e
        return nil
      end

      # Dates Look Like: YYYY-MM-DD
      ret = []
      first = true
      CSV.parse(page.body) do |r|
        # Skip header row
        #   Date,Open,High,Low,Close,Volume,AdjustedVolume
        if first == true
          assert(r.length()==7, "Expected CSV of exactly 7 items")
          first = false
          next
        end
        
        ret.push({ :symbol => @symbol,
                   :open   => Integer(r[1].to_f() * 100),
                   :high   => Integer(r[2].to_f() * 100),
                   :low    => Integer(r[3].to_f() * 100),
                   :close  => Integer(r[4].to_f() * 100),
                   :volume => r[5].to_i(),
                   :date   => Util::ETime::FromDateStr(r[0]) })
      end
      return ret.reverse()
    end

    def getHistoricalDividendAndSplitData(startdate, enddate)
      # Dividend and Split  
      # http://finance.yahoo.com/q/hp \
      #   ?s=C&a=01&b=1&c=2001&d=04&e=21&f=2012&g=v
      # Feb 6 2004 to Apr 7 2012
      #   ?s=C (stock ticker)
      #	  &a=01	(start month from 0)
      #   &b=6	(start date from 1)
      #   &c=2004 (start year)
      #   &d=03   (end month from 0)
      #   &e=7    (end date from 1)
      #   &f=2012 (end year)
      #   &g=v    (dividends and splits)
      assert(startdate.kind_of?(Util::ETime))
      assert(enddate.kind_of?(Util::ETime))
      assert(startdate.dateBefore?(enddate))
      
      startParts = startdate.toDateStr().split('-').map { |p| p.to_i() } # DateStr = YYYYMMDD
      endParts = enddate.toDateStr().split('-').map { |p| p.to_i() }
      params = {
        :s => @symbol,
        :a => startParts[1]-1,
        :b => startParts[2],
        :c => startParts[0],
        :d => endParts[1]-1,
        :e => endParts[2],
        :f => endParts[0],
        :g => :v,
        :ignore => '.csv'
      }
      uri = 'http://finance.yahoo.com/q/hp'
      
      ret = self.helperStockAndDividend(uri, params)
      return ret
    end

    def helperStockAndDividend(uri, params)
      # Default return value
      ret = { :dividends => [], :splits => [] }
      
      # Fetch the page
      page = nil
      begin
        page = @@agent.get(uri, params)
      rescue => e
        logger.error("Failed to get uri=[#{uri}] params=[#{params}] e=[#{e}]")
        return ret
      end
      
      # Parse the page for the stock and dividend data
      #  populates "ret"
      begin
        doc = Nokogiri::HTML(page.body)
        tds = doc.xpath('//td[@class="yfnc_tabledata1"]')

        # Check and get rid of last node
        lastNode = tds.pop()
        assert(lastNode.text.match(/adjusted for dividends and splits/i), "lastNode[#{lastNode.text}] is not expected")
        assert(tds.length() % 2 == 0,
               "tds=[" + tds.map { |td| td.text.gsub(/\s+/, ' ').gsub(/: /, ':') }.join("\n") + "]")
        
        # Load the data into the return value
        0.step(tds.length()-2,2) do |i|
          date=tds[i+0].text
          value=tds[i+1].text.gsub(/\s+/, ' ').gsub(/: /, ':')
          parts = value.split(" ")
          dataType = (parts[1].match(/dividend/i)) ? :dividends : :splits
          ret[dataType].push( { :value => parts[0],
                                :date  => Util::ETime::FromDateStr(date) })
        end
      rescue => e
        # logger.debug("Failed to parse stock and dividend data from page uri=[#{uri}] params=[#{params}] e=[#{e}]") 
        return ret
      end

      # Parse the next link
      h = nil
      begin
        val = doc.xpath('//a[@rel="next"]').pop().attributes['href'].value
        h = Util::EMechanize::UrlToUriParams('http://finance.yahoo.com' + val)
      rescue => e
        # logger.debug("Failed to find next link uri=[#{uri}] params=[#{params}] e=[#{e}]") 
        return ret
      end
      assert(h != nil)

      # Follow the next link
      next_ret = self.helperStockAndDividend(h[:uri], h[:params])

      # Merge the results
      ret[:dividends].concat(next_ret[:dividends])
      ret[:splits].concat(next_ret[:splits])
      return ret
      
    end
  
    def getCurrentOptionData()
      
      params = {
        :s => @symbol,
      }
      uri = 'http://finance.yahoo.com/q/op'

      # Fetch the first option page
      page = nil
      begin
        page = @@agent.get(uri, params)
      rescue => e
        return nil
      end

      # Get the option data for this current page
      ret = self.parseOptionDataFromHtml(page.body)

      # Get a list of the other option pages
      optionLinks = self.parseOptionDateLinksFromHtml(page.body)
      
      for link in optionLinks do
        h = Util::EMechanize::UrlToUriParams('http://finance.yahoo.com' + link)

        # Fetch the first option page
        page = nil
        begin
          page = @@agent.get(h[:uri], h[:params])
        rescue => e
          return nil
        end
        
        next_ret = self.parseOptionDataFromHtml(page.body)
        ret.concat(next_ret)
      end

      return ret
    end

    def parseOptionDateLinksFromHtml(html)
      ret = html.scan(/<a href="(\/q\/op\?s=\w+&amp;m=\d\d\d\d-\d\d)">/).map { |t| t.pop() }
      return ret
    end
    
    def parseOptionDataFromHtml(html)
      # Parse all of the options data from an htmlString.
      # 
      # Nokogiri parser fails to parse the entire yahoo options page.
      #   Thus, we pull small bits of html out and feed them to
      #   Nokogiri.
      
      # Parse out all of the relevant fields into an array
      fields = []
      begin
        # Find the relevant tables via pattern match
        tables = html.scan(/(<table class="yfnc_datamodoutline1".*?<table.*?<\/table>.*?<\/table>)/).map { |t| t.pop() }
        assert(tables.length()==2)

        for table in tables do
          doc = Nokogiri::HTML('<html>' + table + '</html>')
          fields = doc.xpath('//td[@class="yfnc_h" or @class="yfnc_tabledata1"]').map { |td| 
            # Figure out if a change is negative
            is_positive = true
            begin
              if (td.xpath('.//img/@alt').text.match(/down/i))
                is_positive = false
              end
            rescue
              is_positive = true
            end
            # Change the sign
            (is_positive == true) ? td.text : '-'+td.text
          }
          assert(fields.length() % 8 == 0, "fields=[#{fields.to_yaml()}]")
        end
      rescue
        logger.error("Failed to parse option data from html=[#{html}] e=[#{e}] e.backtrace=[#{e.backtrace().to_yaml()}]") 
        return nil
      end

      # Interpret fields and create the return array
      ret = []
      begin
        0.step(fields.length()-8,8) do |i|
          # Load the data into the return value
          #   strike, symbol, last, change, bid, ask, volume, open_interest
          #   symbol field matches "QQQ120616C00030000", and can be used to derive other fields
          
          symbol = nil
          begin
            symbol = fields[i+1]
            assert(symbol != nil) 
            assert(symbol.length()>0)
            assert(!Util::EMath::Numeric?(symbol))
          end

          parts = symbol.scan(/^(\w+)(\d{2})(\d{2})(\d{2})(\w)(\d{8})$/).pop()
          assert(parts.length() == 6, "parts.length[#{parts.length()}] parts.yaml[#{parts.to_yaml()}]")

          strike = nil
          begin
            strike = parts[5].to_i()/10
            assert(strike != nil)
            assert(Util::EMath::Numeric?(strike))
          end

          underlying = nil
          begin
            underlying = parts[0]
            assert(underlying != nil)
            assert(underlying.length()>0)
          end
          
          option_type = nil
          begin
            option_type = parts[4].match(/p/i) ? :put : :call
            assert(option_type != nil)
          end

          expiration = nil
          begin
            expiration = Util::ETime.new(2000+parts[1].to_i(), parts[2].to_i(), parts[3].to_i())
            assert(expiration.kind_of?(Util::ETime))
          end
          
          price = nil
          begin
            price = Integer(fields[i+2].to_f() * 100)
            assert(price != nil)
            assert(Util::EMath::Numeric?(price))
          end

          change = nil
          begin
            change = Integer(fields[i+3].to_f() * 100)
            assert(change != nil)
            assert(Util::EMath::Numeric?(change))
          end

          bid = nil
          begin
            bid = (!Util::EMath::Numeric?(fields[i+4])) ? nil : Integer(fields[i+4].to_f() * 100)
          end

          ask = nil
          begin
            ask = (!Util::EMath::Numeric?(fields[i+5])) ? nil : Integer(fields[i+5].to_f() * 100)
          end

          volume = nil
          begin
            volume = Integer(fields[i+6].gsub(/,/, ''))
            assert(volume != nil)
            assert(Util::EMath::Numeric?(volume))
          end

          interest = nil
          begin
            interest = Integer(fields[i+7].gsub(/,/, ''))
            assert(interest != nil)
            assert(Util::EMath::Numeric?(interest))
          end

          ret.push({ :symbol      => symbol,
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
      rescue => e
        logger.error("Failed to interpret option data from html=[#{html}] e=[#{e}] e.backtrace=[#{e.backtrace().to_yaml()}]") 
        return nil
      end

      return ret
    end

  end


  class MarketDate
    DATE    = 'Cache.MarketData.LastMarketDateTime.value'
    UPDATED = 'Cache.MarketData.LastMarketDateTime.updated'

    def MarketDate.GetLastMarketDate(tickerDataDriver = Finance::DEFAULT_DATA_DRIVER)
      assert(tickerDataDriver == Finance::YahooTicker ||
             tickerDataDriver == Finance::GoogleTicker)
      
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
          t = tickerDataDriver.new('C')
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
                      "newLmd=[#{newLmd.to8601Str()}] " +
                      "updated=[#{now.to8601Str()}]")
        end
        
        return newLmd
      end
    end

    def MarketDate.logger()
      return Rails.logger
    end
    
  end


  class GoogleTicker < TickerDataInterface

    # http://www.google.com/finance?q=akam
    STOCK_URI  = 'http://www.google.com/finance'
    
    # http://www.google.com/finance/historical?q=AKAM \
    #   &startdate=20120201&enddate=20120210&output=csv
    HISTORICAL_STOCK_DATA_URI = 'http://www.google.com/finance/historical'
    
    # http://www.google.com/finance/option_chain?q=akam
    # 
    # http://www.google.com/finance/option_chain? \
    #   q=akam&expd=17&expm=3&expy=2012&output=json
    CURRENT_OPTION_DATA_URI = 'http://www.google.com/finance/option_chain'
    
    def getHistoricalStockData(startdate, enddate)
      assert(startdate.kind_of?(Util::ETime))
      assert(enddate.kind_of?(Util::ETime))
      assert(startdate.dateBefore?(enddate))
      
      params = {
        :q         => @symbol,
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
        
        ret.push({ :symbol => @symbol,
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
        :q      => @symbol,
      }

      page = nil
      begin
        page = @@agent.get(CURRENT_OPTION_DATA_URI, params)
      rescue => e
        logger.error("Unable to find option dates for #{@symbol}")
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
        :q      => @symbol,
        :expd   => dateParts[2],
        :expm   => dateParts[1],
        :expy   => dateParts[0],
        :output => :json
      }
      page = nil
      begin
        page = @@agent.get(CURRENT_OPTION_DATA_URI, params)
      rescue => e
        logger.error("Unable to find option data for #{@symbol}")
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
              underlying = @symbol
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

  #####################################################################
  # Module Constants (must be defined after classes are defined
  
  DEFAULT_DATA_DRIVER = Finance::YahooTicker

end
