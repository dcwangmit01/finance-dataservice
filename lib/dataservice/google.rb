require 'rubygems'
require 'mechanize'
require 'log4r'
require 'csv'
require 'time'
require 'json'

module Google

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


  class GoogleTicker
    @@agent = Mechanize.new()
    @@agent.user_agent_alias = 'Mac Safari'

    def initialize(ticker)
      @ticker = ticker
    end
    
    def doesTickerExist()
      # 7 days ago
      s = (Time.now() - 7*60*60*24).strftime("%Y%m%d")
      # 1 day ago
      e = (Time.now() - 1*60*60*24).strftime("%Y%m%d")
      
      return (self.getHistoricalStockData(s, e) != nil)
    end
    
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

      ret = CSV.parse(page.body) # array of arrays
      return ret
    end
    
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
        .gsub(/(\w+):/, '"\1":')
      ret = JSON.parse(exp)
      return ret
    end
    
    def getOptionData(expy, expm, expd)
      params = {
        :q      => @ticker,
        :expd   => expd,
        :expm   => expm,
        :expy   => expy,
        :output => :json
      }
      page = nil
      begin
        page = @@agent.get(CURRENT_OPTION_DATA_URI, params)
      rescue => e
        logger.error("Unable to find option data for #{@ticker}")
        return nil
      end
      
      ret = JSON.parse(page.body.gsub(/(\w+):/, '"\1":'))
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

