class File

  # Append to a file.
  #
  #   CREDIT: George Moschovitis

  def self.append( file, str )
    File.open( file, 'ab' ) { |f|
      f << str
    }
  end

  # Creates a new file, or overwrites an existing file,
  # and writes a string into it. Can also take a block
  # just like File#open, which is yielded _after_ the
  # string is writ.
  #
  #   str = 'The content for the file'
  #   File.create('myfile.txt', str)
  #
  #   CREDIT: George Moschovitis

  def self.create(path, str='', &blk)
    File.open(path, 'wb') do |f|
      f << str
      blk.call(f) if blk
    end
  end

  # Writes the given data to the given path and closes the file.  This is
  # done in binary mode, complementing <tt>IO.read</tt> in standard Ruby.
  #
  # Returns the number of bytes written.
  #
  #   CREDIT: Gavin Sinclair

  def self.write(path, data)
    File.open(path, "wb") do |file|
      return file.write(data)
    end
  end

  # Writes the given array of data to the given path and closes the file.
  # This is done in binary mode, complementing <tt>IO.readlines</tt> in
  # standard Ruby.
  #
  # Note that +readlines+ (the standard Ruby method) returns an array of lines
  # <em>with newlines intact</em>, whereas +writelines+ uses +puts+, and so
  # appends newlines if necessary.  In this small way, +readlines+ and
  # +writelines+ are not exact opposites.
  #
  # Returns +nil+.
  #
  #   CREDIT: Noah Gibbs
  #   CREDIT: Gavin Sinclair

  def self.writelines(path, data)
    File.open(path, "wb") do |file|
      file.puts(data)
    end
  end

end

