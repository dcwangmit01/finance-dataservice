require 'test_helper'
require 'ruby-debug'

class TickerTest < ActiveSupport::TestCase
  self.use_transactional_fixtures = false

  TICKERS = [:C, :V]

  setup do
  end
  
  test "Ticker.new()" do
    ActiveRecord::Base.transaction do
      TICKERS.each do |ticker|
        logger.info(ticker)
        t1 = Ticker.new()
        t1.name = ticker
        t1.security_type = :stock
        t1.save()
        t1.underlying = t1.id
        t1.save()
      end
    end
  end
  
  def logger
    return Rails.logger
  end

end
