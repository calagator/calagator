class GoogleMapLetterIcon < GoogleMapIcon
  # CALAGATOR: added "rescue nil" to tolerate missing Reloadable
  include Reloadable rescue nil
  
  alias_method :parent_initialize, :initialize
  
  def initialize(letter)
    parent_initialize(:image_url => "http://www.google.com/mapfiles/marker#{letter}.png")
  end
end