class Ticker < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name

  validates :name,
  :presence => true,
  :uniqueness => true,
  :length => {
    :minimum => 1,
    :maximum => 32
  },
  :format => {
    :with => /\A[a-z0-9]+\z/i,
    :message => "Valid values are AlphaNumeric Only"
  }
  
  validates :security_type, 
  :presence => true,
  :length => {
    :minimum => 1,
    :maximum => 32
  },
  :format => {
    :with => /\A(stock|option|currency)\z/,
    :message => "Valid values are (stock|option|currency)"
  }

  validates :underlying,
  :presence => false

  has_many :technicals, :dependent => :destroy
  validates_associated :technicals

  def Ticker.IsInDb(ticker)
    l = Ticker.find_by_name(ticker)
    return (l.length() > 0)
  end

end
