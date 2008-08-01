require 'facets/string/words.rb'
require 'test/unit'

class TestStringWords < Test::Unit::TestCase

  def test_word_filter
    s = "this is a test"
    n = s.word_filter{ |w| "#{w}1" }
    assert_equal( 'this1 is1 a1 test1', n )
  end

  def test_word_filter!
    s = "this is a test"
    s.word_filter!{ |w| "#{w}1" }
    assert_equal( 'this1 is1 a1 test1', s )
  end


  def test_fold_1
    s = "This is\na test.\n\nIt clumps\nlines of text."
    o = "This is a test.\n\nIt clumps lines of text."
    assert_equal( o, s.fold )
  end

  def test_fold_2
    s = "This is\na test.\n\n  This is pre.\n  Leave alone.\n\nIt clumps\nlines of text."
    o = "This is a test.\n\n  This is pre.\n  Leave alone.\n\nIt clumps lines of text."
    assert_equal( o, s.fold(true) )
  end

  def test_word_wrap
    assert_equal "abcde\n12345\nxyzwu\n", "abcde 12345 xyzwu".word_wrap(5)
    assert_equal "abcd\n1234\nxyzw\n", "abcd 1234 xyzw".word_wrap(4)
    assert_equal "abc\n123\n", "abc 123".word_wrap(4)
    assert_equal "abc \n123\n", "abc  123".word_wrap(4)
    assert_equal "abc \n123\n", "abc     123".word_wrap(4)
  end

  def test_word_wrap!
    w = "abcde 12345 xyzwu" ; w.word_wrap!(5)
    assert_equal("abcde\n12345\nxyzwu\n", w)
    w = "abcd 1234 xyzw" ; w.word_wrap!(4)
    assert_equal("abcd\n1234\nxyzw\n", w)
    w = "abc 123" ; w.word_wrap!(4)
    assert_equal "abc\n123\n", w
    w = "abc  123" ; w.word_wrap!(4)
    assert_equal("abc \n123\n", w)
    w = "abc     123" ; w.word_wrap!(4)
    assert_equal("abc \n123\n", w)
  end

# def test_word_wrap
#   assert_equal "abcde-\n12345-\nxyzwu\n", "abcde12345xyzwu".word_wrap(6,2)
#   assert_equal "abcd-\n1234-\nxyzw\n", "abcd1234xyzw".word_wrap(5,2)
#   assert_equal "abc \n123\n", "abc 123".word_wrap(4,2)
#   assert_equal "abc \n123\n", "abc  123".word_wrap(4,2)
#   assert_equal "abc \n123\n", "abc     123".word_wrap(4,2)
# end

  def test_words_01
    x = "a b c\nd e"
    assert_equal( ['a','b','c','d','e'], x.words )
  end

  def test_words_02
    x = "ab cd\nef"
    assert_equal( ['ab','cd','ef'], x.words )
  end

  def test_words_03
    x = "ab cd \n ef-gh"
    assert_equal( ['ab','cd','ef-gh'], x.words )
  end

  def test_each_word
    a = []
    i = "this is a test"
    i.each_word{ |w| a << w }
    assert_equal( ['this', 'is', 'a', 'test'], a )
  end

end
