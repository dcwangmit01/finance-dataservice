require 'test_helper'
require 'dataservice/util'
require 'dataservice/google'

class UtilTest < ActiveSupport::TestCase

  test "ETime.new()" do
    et= Util::ETime.now()
    logger.info(et.to_yaml())
  end

end
