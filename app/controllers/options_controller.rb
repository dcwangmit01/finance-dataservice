require 'rubygems'

class OptionsController < ApplicationController

  def index
    # wget -O - 'http://192.168.3.26:3000/options/index.xml'
    # wget -O - 'http://192.168.3.26:3000/options/index.xml?underlying=csco'

    scope = Option
    if (!params[:underlying].present?)
      options = Option.select('distinct underlying').order('underlying ASC')
    else
      options = Option.select('distinct symbol').order('symbol ASC').where(['underlying = ?', params[:underlying].upcase()])
    end
    
    __export(options)
  end

  def export

    # wget -O - 'http://192.168.3.26:3000/options/export.xml?underlying=csco&symbol=CSCO130119P00015000&underlying=csco&date=2012-03-26&start_date=2012-01-01&end_date=2013-01-01&limit=365&option_type=put'
    # wget -O - 'http://192.168.3.26:3000/options/export.xml?underlying=csco&expiration=2013-01-19&start_expiration=2012-01-01&end_expiration=2014-01-01'
    # wget -O - 'http://192.168.3.26:3000/options/export.xml?underlying=csco&strike=1800&start_strike=1000&end_strike=3000'

    # Start with a reverse
    scope = Option.order('options.date DESC')
    if (params[:underlying].present?)
      scope = scope.where(['underlying = ?', params[:underlying].upcase()])
    end
    if (params[:symbol].present?)
      scope = scope.where(['symbol = ?', params[:symbol].upcase()])
    end
    if (params[:limit].present?)
      scope = scope.limit(params[:limit])
    end
    if (params[:option_type].present?)
      scope = scope.where(['option_type = ?', params[:option_type]])
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
    if (params[:expiration].present?)
      scope = scope.where(['expiration = ?', params[:expiration]])
    end
    if (params[:start_expiration].present?)
      scope = scope.where(['expiration >= ?', params[:start_expiration]])
    end
    if (params[:end_expiration].present?)
      scope = scope.where(['expiration <= ?', params[:end_expiration]])
    end
    if (params[:strike].present?)
      scope = scope.where(['strike = ?', params[:strike]])
    end
    if (params[:start_strike].present?)
      scope = scope.where(['strike >= ?', params[:start_strike]])
    end
    if (params[:end_strike].present?)
      scope = scope.where(['strike <= ?', params[:end_strike]])
    end
    
    __export(scope.reverse)
  end

end
