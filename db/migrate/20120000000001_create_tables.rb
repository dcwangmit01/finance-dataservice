class CreateTables < ActiveRecord::Migration
  def change
    create_table :symbols do |t|
      t.string :name
      t.column  :otype, "ENUM('nasdaq', 'nyse', 'amex')", :null => true
      t.column  :otype, "ENUM('stock', 'option')", :null => false
      t.timestamps
    end

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
      t.column  :otype, "ENUM('put', 'call')", :null => false
      t.date    :exp,        :null => false
      t.integer :strike,     :null => false
      t.integer :price,      :null => true #, :default => :null
      t.integer :change,     :null => true #, :default => :null
      t.integer :bid,        :null => true #, :default => :null
      t.integer :ask,        :null => true #, :default => :null
      t.integer :volume,     :null => false, :default => 0
      t.integer :open_int,   :null => false, :default => 0
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


    # create_table :technicals do |t|
    #   t.references :ticker
    #   t.string :indicator_type
    #   t.integer :value
    #   t.date :date
    #   t.timestamps
    # end
    # add_index :technicals, :ticker_id
    # execute <<-SQL
    # ALTER TABLE technicals
    #   DROP PRIMARY KEY, ADD PRIMARY KEY(id,ticker_id);
    # SQL
    # execute <<-SQL
    # ALTER TABLE technicals
    #   PARTITION BY HASH(ticker_id)
    #   PARTITIONS 8;
    # SQL
  end
end
