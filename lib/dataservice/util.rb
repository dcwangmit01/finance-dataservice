require 'solid_assert'
require 'time'

module Util

  # Enhanced Time
  #   Inherits from: http://ruby-doc.org/core-1.9.3/Time.html
  class ETime < Time

    # Constructors and Convertors
    def ETime.FromDate(d)
      assert(d.kind_of?(d))
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

end
