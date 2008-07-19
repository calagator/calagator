require 'bloomfilter'

bf = BloomFilter.new(100)

names = %w(koshevoy kashivoiov kashmiri kasimov kasami)
places = [
  "Cube Space",
  "CubeSpace",
  "Cubespace",
  "CubSpacer",
  "FreeGeek",
]

names.each{|t| bf.add(t)}
bf.include?('koshevoy')

bf.save("names.bf")
bf.load("names.bf")
