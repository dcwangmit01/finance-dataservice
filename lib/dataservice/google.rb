require 'rubygems'
require 'mechanize'
require 'log4r'
require 'csv'

module Google

  # http://www.google.com/finance/historical?q=AKAM \
  #   &startdate=20120201&enddate=20120210&output=csv
  HISTORICAL_URI = URI('http://www.google.com/finance/historical')

  # http://www.google.com/finance?q=akam
  STOCK_URI  = URI('http://www.google.com/finance')

  # http://www.google.com/finance/option_chain? \
  #   q=akam&expd=17&expm=3&expy=2012&output=json
  OPTION_URI = URI('http://www.google.com/finance/option_chain')


  class GoogleTicker
    @@agent = Mechanize.new()

    def initialize(ticker)
      @ticker = ticker
    end

    def doesTickerExist(startdate, enddate)
      params = {
        :q         => @ticker,
        :startdate => startdate,
        :enddate   => enddate,
        :output    => 'csv'
      }

      page = nil
      begin
        page = @@agent.get(HISTORICAL_URI, params)
      rescue => e
        log.debug("ticker does not exist");
      end

      arr_of_arrs = CSV.parse(page.body)
      logger.info(page.to_yaml);
      logger.info(arr_of_arrs.to_yaml())
    end
    
    def getOptionPage(expd, expm, expy)
      params = {
        :q      => @ticker,
        :expd   => expd,
        :expm   => expm,
        :expy   => expy,
        :output => 'json'
      }
      page = agent.get(OPTION_URI, params)
      logger.info(page.to_yaml);
    end
    
    def logger()
      return Rails.logger
    end

  end
  
end


