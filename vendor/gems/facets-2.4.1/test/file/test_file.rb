require 'facets/file.rb'
require 'test/unit'
require 'tempfile'

class TC_File_Prime < Test::Unit::TestCase

  def test_null
     # TODO
  end

end

class TC_File_Sanitize < Test::Unit::TestCase

  # mock file

  class MockFile < File
    def self.open( fname, mode, &blk )
      blk.call(self)
    end
    def self.read( fname=nil )
      @mock_content.clone
    end
    def self.write( str )
      @mock_content = str
    end
    def self.<<( str )
      (@mock_content ||="") << str
    end
  end

  # TODO Write file identity tests.

  def test_sanitize_01
    assert_equal( "This_is_a_test", MockFile.sanitize('This is a test') )
  end

  def test_sanitize_02
    assert_equal( "test", MockFile.sanitize('This\is\test') )
  end

  def test_sanitize_03
    assert_equal( "test", MockFile.sanitize('This/is/test') )
  end

  def test_sanitize_04
    assert_equal( "te_____st", MockFile.sanitize('This/te#$#@!st') )
  end

  def test_sanitize_05
    assert_equal( "_.", MockFile.sanitize('.') )
  end

  def test_sanitize_06
    assert_equal( "_....", MockFile.sanitize('....') )
  end

end

# class TestFileRead < Test::Unit::TestCase
#
#
#   class MockFile < ::File
#     def open( fname, mode, &blk )
#       blk.call(self)
#     end
#     def read( fname=nil )
#       @mock_content.clone
#     end
#     def write( str )
#       @mock_content = str
#     end
#     def <<( str )
#       (@mock_content ||="") << str
#     end
#   end
#
#   File = MockFile.new
#
#   def test_read_list
#     f = File.write("A\nB\nC")
#     s = File.read_list( f )
#     r = ['A','B','C']
#     assert_equal( r, s )
#   end
#
# end

# Test for facets/file/write.rb

# TODO Needs a file mock.


class TC_File_Write < Test::Unit::TestCase

  def setup
    tmp_dir = Dir::tmpdir # ENV["TMP"] || ENV["TEMP"] || "/tmp"
    raise "Can't find temporary directory" unless File.directory?(tmp_dir)
    @path = File.join(tmp_dir, "ruby_io_test")
  end

  # Test File.write
  def test_file_write
    data_in = "Test data\n"
    nbytes = File.write(@path, data_in)
    data_out = File.read(@path)          # This is standard class method.
    assert_equal(data_in, data_out)
    assert_equal(data_out.size, nbytes)
  end

  # Test File.writelines
  def test_file_writelines
    data_in = %w[one two three four five]
    File.writelines(@path, data_in)
    data_out = File.readlines(@path)     # This is standard class method.
    assert_equal(data_in, data_out.map { |l| l.chomp })
  end

end


# TODO This isn't right, and I'm concerned about acidentally writing a real file.

# class TestFileWrite < Test::Unit::TestCase
#
#   class MockFile < ::File
#     def open( fname, mode, &blk )
#       blk.call(self)
#     end
#     def ead( fname=nil )
#       @mrock_content.clone
#     end
#     def write( str )
#       @mock_content = str
#     end
#     def <<( str )
#       (@mock_content ||="") << str
#     end
#   end
#
#   File = MockFile.new
#
#   def test_create
#     f = "not a real file"
#     t = 'This is a test'
#     File.create( f, t )
#     s = File.read( f )
#     assert_equal( t, s )
#   end
#
#   def test_rewrite
#     f = "not a real file"
#     t = 'This is a test'
#     File.write( t )
#     File.rewrite(f) { |s| s.reverse! }
#     s = File.read(f)
#     assert_equal( t.reverse, s )
#   end
#
# end

