class CreateTables < ActiveRecord::Migration
  def change
    create_table :tickers do |t|
      t.string :name
      #t.column  :ticker_type, "ENUM('stock', 'option')", :null => false
      #t.column  :exchange, "ENUM('nasdaq', 'nyse', 'amex')", :null => true
      #t.column :ticker_type, :enum, :limit => [:stock, :option], :null => false
      #t.column :exchange, :enum, :limit => [:nasdaq, :nyse, :amex], :null => true
      t.string  :ticker_type,  :null => false
      t.string  :exchange,     :null => true
      t.timestamps
    end
    # Rails test framework does not launch execute statements
    #
    # execute <<-SQL
    # ALTER TABLE tickers
    #   CHANGE COLUMN ticker_type ticker_type ENUM('stock', 'option') NOT NULL;
    # SQL
    # execute <<-SQL
    # ALTER TABLE tickers
    #   CHANGE COLUMN exchange exchange  ENUM('nyse', 'nasdaq', 'amex') DEFAULT NULL;
    # SQL

    create_table :stocks do |t|
      t.string  :name,       :null => false
      t.integer :open,       :null => false, :default => 0
      t.integer :high,       :null => false, :default => 0
      t.integer :low,        :null => false, :default => 0
      t.integer :close,      :null => false, :default => 0
      t.integer :volume,     :null => false, :default => 0
      t.integer :split,      :null => false, :default => 0
      t.date    :date,       :null => false
      t.timestamps
    end

    create_table :options do |t|
      t.string  :name
      t.string  :underlying, :null => false
      t.column  :option_type, "ENUM('put', 'call')", :null => false
      t.date    :exp,        :null => false
      t.integer :strike,     :null => false
      t.integer :price,      :null => true #, :default => :null
      t.integer :change,     :null => true #, :default => :null
      t.integer :bid,        :null => true #, :default => :null
      t.integer :ask,        :null => true #, :default => :null
      t.integer :volume,     :null => false, :default => 0
      t.integer :interest,   :null => false, :default => 0
      t.integer :split,      :null => false, :default => 0
      t.date    :date,       :null => false
      t.timestamps
    end
    # Rails will not allow integer columns to default to null values
    # unless explicity set below
    change_column_default(:options, :price, nil)
    change_column_default(:options, :change, nil)
    change_column_default(:options, :bid, nil)
    change_column_default(:options, :ask, nil)
  end

end
