class Ticker < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name
  validates_format_of :name, :with => /\A[a-z0-9]+\z/i

  validates :name, :presence => true
  validates :security_type, :presence => true, :length => { :minimum => 4 }
  has_many :technicals, :dependent => :destroy


end
