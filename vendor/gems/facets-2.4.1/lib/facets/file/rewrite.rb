class File

  # Opens a file as a string and writes back the string to the file at
  # the end of the block.
  #
  # Returns the number of written bytes or +nil+ if the file wasn't
  # modified.
  #
  # Note that the file will even be written back in case the block
  # raises an exception.
  #
  # Mode can either be "b" or "+" and specifies to open the file in
  # binary mode (no mapping of the plattform's newlines to "\n" is
  # done) or to append to it.
  #
  #   # Reverse contents of "message"
  #   File.rewrite("message") { |str| str.reverse! }
  #
  #   # Replace "foo" by "bar" in "binary"
  #   File.rewrite("binary", "b") { |str| str.gsub!("foo", "bar") }
  #
  #   CREDIT: George Moschovitis
  #--
  # TODO Should it be in-place modification like this? Or would it be better
  # if whatever the block returns is written to the file instead?
  #++

  def self.rewrite(name, mode = "") #:yield:
    unless block_given?
      raise(ArgumentError, "Need to supply block to File.open_as_string")
    end

    if mode.is_a?(Numeric) then
      flag, mode = mode, ""
      mode += "b" if flag & File::Constants::BINARY != 0
      mode += "+" if flag & File::Constants::APPEND != 0
    else
      mode.delete!("^b+")
    end

    str = File.open(name, "r#{mode}") { |file| file.read } #rescue ""
    old_str = str.clone

    begin
      yield str
    ensure
      if old_str != str then
        File.open(name, "w#{mode}") { |file| file.write(str) }
      end
    end
  end

end

