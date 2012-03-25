require 'test_helper'

class StockTest < ActiveSupport::TestCase
  test "Stock.Update" do
    ActiveRecord::Base.transaction do
      Finance::DEFAULT_DATA_DRIVER = Finance::YahooTicker
      Stock::PRIME = Util::ETime.new(2012, 1, 1)
      Stock::Update(:AKAM)
    end

    ActiveRecord::Base.transaction do
      Finance::DEFAULT_DATA_DRIVER = Finance::GoogleTicker
      Stock::PRIME = Util::ETime.new(2012, 1, 1)
      Stock::Update(:CSCO)
    end
  end
end
