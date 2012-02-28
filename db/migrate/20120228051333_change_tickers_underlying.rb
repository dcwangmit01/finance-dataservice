class ChangeTickersUnderlying < ActiveRecord::Migration
  def change
    change_column("tickers", "underlying", :integer, :null => true)
  end
end
