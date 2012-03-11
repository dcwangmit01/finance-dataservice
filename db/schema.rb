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
    # Rails test framework does not launch execute statements when creating DBs
    #   Can't use this:
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
# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120000000001) do

  create_table "options", :force => true do |t|
    t.string   "name"
    t.string   "underlying",                              :null => false
    t.string   "option_type", :limit => 0,                :null => false
    t.date     "exp",                                     :null => false
    t.integer  "strike",                                  :null => false
    t.integer  "price"
    t.integer  "change"
    t.integer  "bid"
    t.integer  "ask"
    t.integer  "volume",                   :default => 0, :null => false
    t.integer  "interest",                 :default => 0, :null => false
    t.integer  "split",                    :default => 0, :null => false
    t.date     "date",                                    :null => false
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
  end

  create_table "stocks", :force => true do |t|
    t.string   "name",                      :null => false
    t.integer  "open",       :default => 0, :null => false
    t.integer  "high",       :default => 0, :null => false
    t.integer  "low",        :default => 0, :null => false
    t.integer  "close",      :default => 0, :null => false
    t.integer  "volume",     :default => 0, :null => false
    t.integer  "split",      :default => 0, :null => false
    t.date     "date",                      :null => false
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "tickers", :force => true do |t|
    t.string   "name"
    t.string   "ticker_type", :null => false
    t.string   "exchange"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

end
