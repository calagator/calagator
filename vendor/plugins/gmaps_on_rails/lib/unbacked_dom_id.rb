# UnbackedDomId
module UnbackedDomId
  ##
  # Implementation of http://codefluency.com/articles/2006/05/30/rails-views-dom-id-scheme
  #
  #  my_special_race_car.dom_id
  #  => "race_car_1"
  #
  #  another_race_car.dom_id
  #  => "race_car_2"
  # 
  def dom_id(prefix=nil)
    id = self.object_id.to_s.gsub('-', '_')
    class_name = self.class.name.gsub(/::/, '/').
                 gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
                 gsub(/([a-z\d])([A-Z])/,'\1_\2').
                 tr("-", "_").
                 downcase
    prefix = prefix.nil? ? class_name : "#{prefix}_#{class_name}"
    "#{prefix}_#{id}"
  end
end