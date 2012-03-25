require 'test_helper'
require 'dataservice/google'
require 'dataservice/finance'
require 'pp'

class FinanceTest < ActiveSupport::TestCase

  def test_EMechanize_UrlUrlParams()
    begin
      url1 = "http://finance.yahoo.com/q/hp?s=C&a=2&b=28&c=1992&d=2&e=22&f=2012&g=v&ignore=.csv"
      h = Util::EMechanize::UrlToUriParams(url1)
      assert(h != nil)
      assert(h[:uri] != nil)
      assert(h[:params] != nil)
      assert(h[:uri] == 'http://finance.yahoo.com/q/hp')
      assert(h[:params]['s'] == 'C')
      assert(h[:params]['a'] == '2')
      assert(h[:params]['b'] == '28')
      assert(h[:params]['c'] == '1992')
      assert(h[:params]['d'] == '2')
      assert(h[:params]['e'] == '22')
      assert(h[:params]['f'] == '2012')
      assert(h[:params]['g'] == 'v')
      assert(h[:params]['ignore'] == '.csv')
      
      url2 = Util::EMechanize::UriParamsToUrl(h[:uri], h[:params])
      assert(url1 == url2)
      logger.info("url1=[#{url1}] url2=[#{url2}]")
    end

    begin
      url1 = "http://finance.yahoo.com/q/hp"
      h = Util::EMechanize::UrlToUriParams(url1)
      assert(h != nil)
      assert(h[:uri] != nil)
      assert(h[:params] != nil)
      assert(h[:uri] == 'http://finance.yahoo.com/q/hp')
      assert(h[:params].length() == 0)

      url2 = Util::EMechanize::UriParamsToUrl(h[:uri], h[:params])
      logger.info("url1=[#{url1}] url2=[#{url2}]")      
      assert(url1 == url2)
    end
  end

  def dtest_Finance_YahooTicker_DividendsAndSplits()
    # From 20 years ago to 1 day ago
    s = Util::ETime.now().cloneDiffSeconds(-20*365*60*60*24)
    e = Util::ETime.now().cloneDiffSeconds(-1*60*60*24)
    
    begin
      yp = Finance::YahooTicker.new(:C)
      sd = yp.getHistoricalDividendAndSplitData(s, e)
      assert(sd != nil)
      logger.info(sd.to_yaml())
    end
    
    begin
      yp = Finance::YahooTicker.new(:AKAM)
      sd = yp.getHistoricalDividendAndSplitData(s, e)
      assert(sd != nil)
      logger.info(sd.to_yaml())
    end

  end

  def dtest_Finance_YahooTicker_HistoricalStockData()
    # From 8 days ago to 1 day ago
    s = Util::ETime.now().cloneDiffSeconds(-8*60*60*24)
    e = Util::ETime.now().cloneDiffSeconds(-1*60*60*24)
    
    begin
      yp = Finance::YahooTicker.new(:C)
      v = yp.getHistoricalStockData(s, e)
      assert(v != nil)
      logger.info(v.to_yaml())
    end
  end

  def dtest_Finance_YahooTicker_CurrentOptionData()

    yp = Finance::YahooTicker.new(:C)
    v = yp.getCurrentOptionData()
    assert(v != nil)
    logger.info(v.to_yaml())
  end

  def dtest_DynamicClasses()
    c = Finance::YahooTicker
    d = c.new('C')
    logger.info(d.doesTickerExist())
  end

  def test_Finance_MarketDate_GetLastMarketDate()

    lmd = Finance::MarketDate::GetLastMarketDate()
    logger.info(lmd)

    lmd1 = Finance::MarketDate::GetLastMarketDate(Finance::YahooTicker)
    logger.info(lmd1)
    
    lmd2 = Finance::MarketDate::GetLastMarketDate(Finance::GoogleTicker)
    logger.info(lmd2)

  end

  

end
