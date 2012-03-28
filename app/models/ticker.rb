require 'dataservice/util'
require 'dataservice/finance'

class Ticker < ActiveRecord::Base

  def Ticker.Exist?(symbol)
    assert(symbol.kind_of?(String) || symbol.kind_of?(Symbol))
    ticker = Ticker.find_by_symbol(symbol)
    return (ticker != nil)
  end

  def logger()
    return Rails.logger
  end

end
