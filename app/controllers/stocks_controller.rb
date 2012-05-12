require 'rubygems'

class StocksController < ApplicationController

  def index
    
    # wget -O - 'https://dataservice.yourdomain.com/stocks/index.csv'
    # wget -O - 'https://dataservice.yourdomain.com/stocks/index.xml'
    # wget -O - 'https://dataservice.yourdomain.com/stocks/index.json'

    stocks = Stock.select('distinct symbol').order('symbol ASC')
    __export(stocks)
  end

  def export

    # wget -O - 'https://dataservice.yourdomain.com/stocks/export.csv?symbol=csco&start_date=2012-01-01&end_date=2012-02-01&limit=365'
    # wget -O - 'https://dataservice.yourdomain.com/stocks/export.xml?symbol=csco&start_date=2012-01-01&end_date=2012-02-01&limit=365'
    # wget -O - 'https://dataservice.yourdomain.com/stocks/export.json?symbol=csco&start_date=2012-01-01&end_date=2012-02-01&limit=365'
    # wget -O - 'https://dataservice.yourdomain.com/stocks/export.xml?symbol=csco&start_date=2012-01-01&end_date=2012-02-01&limit=365&date=2012-01-26'


    # Start with a reverse
    scope = Stock.order('stocks.date DESC')
    if (params[:symbol].present?)
      scope = scope.where(['symbol = ?', params[:symbol].upcase()])
    end
    if (params[:limit].present?)
      scope = scope.limit(params[:limit])
    end
    if (params[:date].present?)
      scope = scope.where(['date = ?', params[:date]])
    end
    if (params[:start_date].present?)
      scope = scope.where(['date >= ?', params[:start_date]])
    end
    if (params[:end_date].present?)
      scope = scope.where(['date <= ?', params[:end_date]])
    end
    
    __export(scope.reverse)
  end

end
