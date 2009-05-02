# Time.today was eliminated in RubyGems 1.3.2. This monkey patch puts it back.
# https://rubyforge.org/tracker/index.php?func=detail&aid=25564&group_id=126&atid=575

class Time
  def self.today
    return Date.today.to_time
  end
end
