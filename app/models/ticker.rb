require 'dataservice/util'
require 'dataservice/finance'

class Ticker < ActiveRecord::Base

  def logger()
    return Rails.logger
  end

end
