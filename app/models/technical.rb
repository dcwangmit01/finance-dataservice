class Technical < ActiveRecord::Base
  
  # Explicitly force the primary key, because the technicals table is
  # hand-tweaked with a primary multi-key to support partitioning.
  self.primary_key = :id

  validates :indicator_type,
  :presence => true,
  :length => {
    :minimum => 2,
    :maximum => 32
  },
  :format => {
    :with => /\A[a-z0-9]+\z/i,
    :message => "Valid values are AlphaNumeric Only"
  }

  validates :date,
  :presence => true

  validates :value,
  :presence => true,
  :numericality => { 
    :only_integer => true,
    :greater_than_or_equal_to => 0  
  }

  validates :ticker_id,
  :presence => true

  belongs_to :ticker
end
