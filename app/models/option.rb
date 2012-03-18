class Option < ActiveRecord::Base

  def Option.GetLastRecord(name)
    # Get the latest historical record to see when it was last updated
    s = Option.find(:last, :order => "date ASC", :conditions => { :underlying => t.name })
    return s # nil is okay
  end

  def log()
    return Rails.logger
  end

end
