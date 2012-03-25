require 'solid_assert'
require 'time'
require 'mechanize'

module Util

  class EMath
    def EMath.Numeric?(object)
        true if Float(object) rescue false
    end
  end

  # Enhanced Mechanize
  #   Inherits from:

  class EMechanize < Mechanize

    THROTTLE_MIN = 0
    THROTTLE_MAX = 1
    
    def get(uri, parameters = [], referer = nil, headers = {})
      sleepTime = Random.rand(THROTTLE_MIN..THROTTLE_MAX)
      logger.info("Making Web Request: " +
                  "url=[#{EMechanize::UriParamsToUrl(uri, parameters)}] " +
                  "sleeping=[#{sleepTime}]")
      sleep(sleepTime)
      super
    end

    def EMechanize.UriParamsToUrl(uri, params)
      assert(uri.kind_of?(String), "Wrong type for uri class=[#{uri.class}]")
      assert(uri.length()>0)
      assert(uri.match(/^http/))

      url = nil
      if (params == nil || params.length() == 0)
        url = uri
      else
        url = uri + '?' + params.map{ |k, v|"#{k}=#{v}" }.join('&')
      end
      
      return url
    end

    def EMechanize.UrlToUriParams(url)
      assert(url.kind_of?(String))
      assert(url.length()>0)
      assert(url.match(/^http/))

      ret = nil
      if !url.match(/\?/)
        ret = { :uri => url, :params => {} }
      else
        parts = url.split(/\?/)
        assert(parts.length()==2, parts)
        uri = parts[0]
        params = {}
        for p in parts[1].split('&')
          parts = p.split('=')
          assert(parts.length()==2)
          params[parts[0]] = parts[1]
        end
        
        ret = { :uri => uri, :params => params }
      end

      assert(ret[:uri] != nil)
      assert(ret[:params] != nil)
      return ret
    end
    
    def logger()
      return Rails.logger
    end
  end


  # Enhanced Time
  #   Inherits from: http://ruby-doc.org/core-1.9.3/Time.html
  class ETime < Time

    # Constructors and Convertors
    def ETime.FromDate(d)
      assert(d.kind_of?(Date))
      return ETime.new(d.year, d.mon, d.day)
    end
    
    def toDate()
      return Date.parse(self.to_s())
    end
    
    def ETime.From8601Str(iso8601Str)
      assert(iso8601Str.kind_of?(String))
      time = Time.parse(iso8601Str)
      r = Util::ETime::at(time.to_i())
      assert(iso8601Str == r.to8601Str())
      return r
    end

    def to8601Str()
      return self.iso8601()
    end

    def ETime.FromDateStr(s)
      assert(s.kind_of?(String))
      d = Date.parse(s)
      assert(d.kind_of?(Date))
      r = Util::ETime.new(d.year, d.mon, d.day)
      assert(r.kind_of?(ETime))
      return r
    end

    def toDateStr()
      return self.strftime("%Y-%m-%d")
    end

    def toDateStrYYYYMMDD()
      return self.strftime("%Y%m%d")
    end

    # Cloners
    def cloneDiffSeconds(secs)
      assert(secs.kind_of?(Integer))
      return ETime.at(self.to_f()+secs)
    end

    # DateTime comparisons
    def equal?(t)
      assert(t.kind_of?(ETime))
      return ((self <=> t) == 0)
    end

    def before?(t)
      assert(t.kind_of?(ETime))
      return ((self <=> t) == -1)
    end

    def after?(t)
      assert(t.kind_of?(ETime))
      return ((self <=> t) == 1)
    end

    def between?(t1, t2)
      assert(t1.kind_of?(ETime))
      assert(t2.kind_of?(ETime))
      return (self.after?(t1) && self.before?(t2))
    end

    # Date part comparisons
    def dateEqual?(t)
      assert(t.kind_of?(ETime))
      return (self.year == t.year && self.yday == t.yday)
    end

    def dateBefore?(t)
      assert(t.kind_of?(ETime))
      return true if self.year < t.year
      return true if self.yday < t.yday
      return false
    end

    def dateAfter?(t)
      assert(t.kind_of?(ETime))
      return true if self.year > t.year
      return true if self.yday > t.yday
      return false
    end

    def dateBetween?(t1, t2)
      assert(t1.kind_of?(ETime))
      assert(t2.kind_of?(ETime))
      return (self.dateAfter?(t1) && self.dateBefore?(t2))
    end

    # Time part comparisons
    def timeEqual?(t)
      assert(t.kind_of?(ETime))
      return (self.hour == t.hour &&
              self.min  == t.min  &&
              self.sec  == t.sec  &&
              self.nsec == t.nsec)
    end

    def timeBefore?(t)
      assert(t.kind_of?(ETime))
      return true if self.hour < t.hour
      return true if self.min  < t.min
      return true if self.sec  < t.sec
      return true if self.nsec < t.nsec
      return false
    end

    def timeAfter?(t)
      assert(t.kind_of?(ETime))
      return true if self.hour > t.hour
      return true if self.min  > t.min
      return true if self.sec  > t.sec
      return true if self.nsec > t.nsec
      return false
    end

    def timeBetween?(t1, t2)
      assert(t1.kind_of?(ETime))
      assert(t2.kind_of?(ETime))
      return (self.timeAfter?(t1) && self.timeBefore?(t2))
    end

    # Questions
    def weekend?()
      return (self.saturday?() || self.sunday?())
    end

    def weekday?()
      return !(self.weekend?)
    end
    
  end


 
  class MarketTime
    
    # Grace time means: before and after market hours where we do not
    # want to fetch data, allowing for data providers to settle
    TIMES = {
      # gb = gracetime before
      # ga = gracetime after
      :open_gb  => { :hour => 06, :min => 00 },
      :open     => { :hour => 06, :min => 30 },
      :open_ga  => { :hour => 07, :min => 00 },
      :close_gb => { :hour => 12, :min => 30 },
      :close    => { :hour => 13, :min => 00 },
      :close_ga => { :hour => 14, :min => 00 } }

    # Helpers
    def MarketTime.BeforeHourMin?(time, hour, min)
      assert(time.kind_of?(ETime))
      assert(hour.kind_of?(Integer))
      assert(min.kind_of?(Integer))

      return ((time.hour * 60) + time.min) < ((hour * 60) + min)
    end

    def MarketTime.AfterHourMin?(time, hour, min)
      assert(time.kind_of?(ETime))
      assert(hour.kind_of?(Integer))
      assert(min.kind_of?(Integer))

      return ((time.hour * 60) + time.min) > ((hour * 60) + min)
    end

    # MarketTime Queries
    def MarketTime.BetweenHourMin?(time, hour1, min1, hour2, min2)
      assert(time.kind_of?(ETime))
      assert(hour1.kind_of?(Integer))
      assert(min1.kind_of?(Integer))
      assert(hour2.kind_of?(Integer))
      assert(min2.kind_of?(Integer))
      return (MarketTime::AfterHourMin?(time, hour1, min1) &&
              MarketTime::BeforeHourMin?(time, hour2, min2))
    end
    
    def MarketTime.BeforeOpen?(time)
      assert(time.kind_of?(Util::ETime))
      return MarketTime::BeforeHourMin?(time,
                                        MarketTime::TIMES[:open][:hour],
                                        MarketTime::TIMES[:open][:min])
    end
    
    def MarketTime.AfterOpen?(time)
      assert(time.kind_of?(Util::ETime))
      return (!MarketTime::BeforeOpen?(time))
    end

    def MarketTime.BeforeClose?(time)
      assert(time.kind_of?(Util::ETime))
      return MarketTime::BeforeHourMin?(time,
                                        MarketTime::TIMES[:close][:hour],
                                        MarketTime::TIMES[:close][:min])
    end

    def MarketTime.AfterClose?(time)
      assert(time.kind_of?(Util::ETime))
      return (!MarketTime::BeforeClose?(time))
    end

    def MarketTime.Open?(time)
      assert(time.kind_of?(Util::ETime))
      return (!MarketTime::Close?(time))
    end

    def MarketTime.Close?(time)
      assert(time.kind_of?(Util::ETime))
      return (MarketTime::BeforeOpen?(time) || MarketTime::AfterClose?(time))
    end
    
    def MarketTime.OpenGrace?(time)
      assert(time.kind_of?(Util::ETime))
      return (MarketTime::BetweenHourMin?(time,
                                          MarketTime::TIMES[:open_gb][:hour],
                                          MarketTime::TIMES[:open_gb][:min],
                                          MarketTime::TIMES[:open_ga][:hour],
                                          MarketTime::TIMES[:open_ga][:min]))
    end
    
    def MarketTime.CloseGrace?(time)
      assert(time.kind_of?(Util::ETime))
      return (MarketTime::BetweenHourMin?(time,
                                          MarketTime::TIMES[:close_gb][:hour],
                                          MarketTime::TIMES[:close_gb][:min],
                                          MarketTime::TIMES[:close_ga][:hour],
                                          MarketTime::TIMES[:close_ga][:min]))
    end

    def MarketTime.Grace?(time)
      assert(time.kind_of?(Util::ETime))
      return (MarketTime::OpenGrace?(time) || MarketTime::CloseGrace?(time))
    end
    
  end

end
