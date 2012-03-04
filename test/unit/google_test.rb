require 'test_helper'
require 'dataservice/google'

class GoogleTest < ActiveSupport::TestCase
  test "new" do
    gt = Google::GoogleTicker.new(:akam)
    logger.info(gt.to_yaml())
  end

  test "doesTickerExist" do
    gt = Google::GoogleTicker.new(:azam)
    gt.doesTickerExist('20120101', '20120110')
    logger.info(gt.to_yaml())
  end
end
