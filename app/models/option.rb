class Option < ActiveRecord::Base

  def Option.EnsureExists(name)
    
  end

  def Option.GetLastRecordDate(name)

  end

  def log()
    return Rails.logger
  end

end
