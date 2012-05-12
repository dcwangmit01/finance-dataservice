
== Overview

Given a list of financial tickers, this application will fetch stock,
option, dividend, and split data from Yahoo Finance and store
everything in a Mysql Database. A backend webservice provides filtered
access to the data over a simple web-based API served as CSV, JSON, or
XML formats.


== Usage

=== Web API

* HTTP query strings allow filtering parameters
** Stocks: ~/finance-dataservice/app/controllers/stocks_controller.rb
*** symbol
*** limit
*** date
*** start_date
*** end_date

** Options: ~/finance-dataservice/app/controllers/options_controller.rb
*** underlying
*** symbol
*** limit
*** option_type
*** date
*** start_date
*** end_date
*** expiration
*** start_expiration
*** end_expiration
*** strike
*** start_strike
*** end_strike

Examples
* Get a list of stocks for which data is available in CSV, XML, or JSON formats
  wget -O - 'https://dataservice.yourdomain.com/stocks/index.csv'
  wget -O - 'https://dataservice.yourdomain.com/stocks/index.xml'
  wget -O - 'https://dataservice.yourdomain.com/stocks/index.json'

* Stock data downloads, in csv, xml, and json
  wget -O - 'https://dataservice.yourdomain.com/stocks/export.csv?symbol=csco&start_date=2012-01-01&end_date=2012-02-01&limit=365'
  wget -O - 'https://dataservice.yourdomain.com/stocks/export.xml?symbol=csco&start_date=2012-01-01&end_date=2012-02-01&limit=365'
  wget -O - 'https://dataservice.yourdomain.com/stocks/export.json?symbol=csco&start_date=2012-01-01&end_date=2012-02-01&limit=365&date=2012-01-26'

* Get a list of option underlyings
  wget -O - 'https://dataservice.yourdomain.com/options/index.csv'
  wget -O - 'https://dataservice.yourdomain.com/options/index.xml'
  wget -O - 'https://dataservice.yourdomain.com/options/index.json'

* Get a list of option symbols for a particular underlying
  wget -O - 'https://dataservice.yourdomain.com/options/index.csv?underlying=csco'
  wget -O - 'https://dataservice.yourdomain.com/options/index.xml?underlying=csco'
  wget -O - 'https://dataservice.yourdomain.com/options/index.json?underlying=csco'

* Option data downloads, in csv, xml, and json
  wget -O - 'https://dataservice.yourdomain.com/options/export.xml?underlying=csco&symbol=CSCO130119P00015000&underlying=csco&date=2012-03-26&start_date=2012-01-01&end_date=2013-01-01&limit=365&option_type=put'
  wget -O - 'https://dataservice.yourdomain.com/options/export.xml?underlying=csco&expiration=2013-01-19&start_expiration=2012-01-01&end_expiration=2014-01-01'
  wget -O - 'https://dataservice.yourdomain.com/options/export.xml?underlying=csco&strike=1800&start_strike=1000&end_strike=3000'

=== Data Collection Service

* Edit the data collector script and set the list of hard-coded stock tickers that you want to collect data for
  emacs ~/finance-dataservice/bin/update.rb

* Run the data collector script
  script/rails runner -e production bin/update.rb


== Install

* Clone a new linux machine (Ubuntu 10.04 LTS)
* Install some utils
  sudo apt-get update
  sudo apt-get install curl git bash
* Install RVM
  bash -s stable < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer)
  source ~/.bashrc
  rvm requirements
    # Then follow the instructions
    sudo apt-get update
    sudo apt-get install build-essential openssl libreadline6 \
      libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev \
      libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev \
      libxslt-dev autoconf libc6-dev ncurses-dev automake libtool \
      bison subversion
* Install Mysql
  sudo apt-get install mysql-server mysql-client libmysql-ruby libmysqlclient-dev
  sudo apt-get install nodejs
* Install ruby
  rvm install 1.9.3
* Set the default ruby to be 
  rvm --default use 1.9.3
* Install missing gems
  # Install one in particular, which requires an argument
  gem install ruby-debug19 -- --with-ruby-include=\$rvm_path/src/ruby-1.9.3-p125 
  gem install linecache19 -- --with-ruby-include=\$rvm_path/src/ruby-1.9.3-p125
  # then install the rest
  bundle install


* Clone the repository
  git clone ssh://you@yourdomain.com:<portnumber>/var/git/dataservice
  git config --global user.name "First Last"
  git config --global user.email "you@yourdomain.com"


* Test
  rake db:drop db:create db:migrate test:prepare
  rake test
  
* Run the Program
  RAILS_ENV=production rake db:drop db:create db:migrate
  script/rails runner -e production bin/update.rb



== Notes

* License
** http://www.opensource.org/licenses/mit-license.php

* This project is not production quality code.
** It's a basic home project I used to understand the Ruby and Rails hype.
** I don't plan on investing in this project beyond what is minimally useful, so feel free to clone and own it.

* Issues
** The default RoR WEBrick server leaks memory and eventually crashes.  You should use a different server.
** The RESTful webapi is susceptable to SQL injection attacks, since HTTP GET args are fed directly to the DB query.
** Please make sure you protect the webapi with SSL and at least HTTP Basic Auth.
** I run the data gathering script in a bash while loop.  It probably needs to be a crond task or a Ruby "service".

