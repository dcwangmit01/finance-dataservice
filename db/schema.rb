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

  create_table "app_settings", :force => true do |t|
    t.string   "name"
    t.string   "value"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "dividends", :force => true do |t|
    t.string  "symbol",                  :null => false
    t.integer "dividend", :default => 0, :null => false
    t.date    "date",                    :null => false
  end

  create_table "options", :force => true do |t|
    t.string   "symbol",                   :null => false
    t.string   "underlying",               :null => false
    t.string   "option_type", :limit => 0, :null => false
    t.date     "expiration",               :null => false
    t.integer  "strike",                   :null => false
    t.integer  "price"
    t.integer  "change"
    t.integer  "bid"
    t.integer  "ask"
    t.integer  "volume"
    t.integer  "interest"
    t.date     "date",                     :null => false
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  create_table "splits", :force => true do |t|
    t.string  "symbol",                 :null => false
    t.integer "split_a", :default => 0, :null => false
    t.integer "split_b", :default => 0, :null => false
    t.date    "date",                   :null => false
  end

  create_table "stocks", :force => true do |t|
    t.string   "symbol",                    :null => false
    t.integer  "open",       :default => 0, :null => false
    t.integer  "high",       :default => 0, :null => false
    t.integer  "low",        :default => 0, :null => false
    t.integer  "close",      :default => 0, :null => false
    t.integer  "volume",     :default => 0, :null => false
    t.date     "date",                      :null => false
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "tickers", :force => true do |t|
    t.string   "symbol"
    t.string   "symbol_type", :limit => 0,                       :null => false
    t.string   "exchange",                 :default => "null"
    t.string   "status",                   :default => "active", :null => false
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
  end

end
