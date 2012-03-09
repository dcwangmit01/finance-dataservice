require 'test_helper'
require 'ruby-debug'

class SymbolTest < ActiveSupport::TestCase
  self.use_transactional_fixtures = false

  SYMBOLS = [:C, :V]

  setup do
  end
  
  test "Symbol.new()" do
    ActiveRecord::Base.transaction do
      SYMBOLS.each do |symbol|
        logger.info(symbol)
        t1 = Symbol.new()
        t1.name = symbol
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
