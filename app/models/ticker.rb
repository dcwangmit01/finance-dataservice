require 'dataservice/util'
require 'dataservice/google'

class Ticker < ActiveRecord::Base

  def Ticker.UpdateAll()
    Stock::UpdateAll()
  end

  def Ticker.Exists(name)
    ticker = Ticker.find_by_name(name)
    return (ticker != nil)
  end
  
  def logger()
    return Rails.logger
  end

end
