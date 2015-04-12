# Interleave an array with another. Similar to zip, but will nil pad the
# reciever if needed. Only accepts one array argument.
Array.send(:define_method, :interleave) do |other|
  if length > other.length
    zip(other)
  else
    other.zip(self).map(&:reverse)
  end
end
