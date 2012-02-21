class AddUnderlyingToTickers < ActiveRecord::Migration
  def change
    add_column :tickers, :underlying, :string
  end
end
