require 'test_helper'
require 'ruby-debug'

class TickerTest < ActiveSupport::TestCase


  setup do
    self.use_transactional_fixtures = false
    logger.info("Disabling Transactions")
  end

  test "Ticker.t2" do
  end

  test "Ticker.new()" do
    

    ActiveRecord::Base.transaction do
      t1 = Ticker.new()
      t1.name = 'ibm'
      t1.security_type = :stock
      t1.save()
      assert(t1.save())
      logger.info(t1)

      t2 = Ticker.find_by_name('ibm')
      assert_equal(t1.name, t2.name)

      t2.underlying = t1.id
      t2.save()
      logger.info(t2)
    end
    
  end
  
  def logger
    return Rails.logger
  end


end
