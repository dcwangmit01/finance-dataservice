require 'test_helper'

class OptionTest < ActiveSupport::TestCase
  test "Option.Update" do
    ActiveRecord::Base.transaction do
      Finance::DEFAULT_DATA_DRIVER = Finance::YahooTicker
      Option::PRIME = Util::ETime.new(2012, 1, 1)
      Option::Update(:AKAM)
    end

    ActiveRecord::Base.transaction do
      Finance::DEFAULT_DATA_DRIVER = Finance::GoogleTicker
      Option::PRIME = Util::ETime.new(2012, 1, 1)
      Option::Update(:CSCO)
    end
end
