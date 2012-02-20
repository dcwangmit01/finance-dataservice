class Ticker < ActiveRecord::Base
  validates :name, :presence => true
  validates :security_type, :presence => true, :length => { :minimum => 4 }
  has_many :technicals, :dependent => :destroy
end
