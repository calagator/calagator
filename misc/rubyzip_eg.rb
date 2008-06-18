#!/usr/bin/env ruby

require 'rubygems'
require 'zip/zip'

include Zip

#  write
#ZipOutputStream.new("test.zip") do |zos|
#  p "Writing"
#  zos.put_next_entry("name")
#  zos.write(File.read(".hgignore"))
#end
zos = ZipOutputStream.new("test.zip")
p "Writing"
zos.put_next_entry("name")
zos.write(File.read(".hgignore"))
zos.close

# read
dir = "testzip"
Dir.mkdir(dir) rescue nil
zis = ZipInputStream.new("test.zip")
while entry = zis.get_next_entry
  p entry.name
  File.open("#{dir}/#{entry.name}", "w+"){|h| h.write(zis.read)}
end
zis.close
