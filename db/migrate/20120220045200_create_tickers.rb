class CreateTickers < ActiveRecord::Migration
  def change
    create_table :tickers do |t|
      t.string :name
      t.string :security_type

      t.timestamps
    end
  end
end
