
require 'time'

module Util

  # Enhanced Time
  #   Inherits from: http://ruby-doc.org/core-1.9.3/Time.html
  class ETime < Time

    def to_strYYYYMMDD()
      return self.strftime("%Y%m%d")
    end

    def cloneDiffSeconds(numsecs)
      return ETime.at(self.to_f()+numsecs)
    end
    
    def equal?(t)
      return ((self <=> t) == 0)
    end

    def before?(t)
      return ((self <=> t) == -1)
    end

    def after?(t)
      return ((self <=> t) == 1)
    end

    def between?(t1, t2)
      return (self.after?(t1) && self.before?(t2))
    end

    
    def dateEqual?(t)
      return (self.year == t.year && self.yday == t.yday)
    end

    def dateBefore?(t)
      return true if self.year < t.year
      return true if self.yday < t.yday
      return false
    end

    def dateAfter?(t)
      return true if self.year > t.year
      return true if self.yday > t.yday
      return false
    end

    def ETime.FromDate(date)
      return ETime.new(date.year, date.mon, date.day)
    end
    
    def toDate()
      return Date.parse(self.to_s())
    end


  end

end
