# Test facets/stylize.rb

require 'facets/style.rb'
require 'test/unit'

class TestStylize < Test::Unit::TestCase

  def test_camelize
    assert_equal( 'ThisIsIt', 'this_is_it'.style(:camelize) )
  end

  def test_humanize
    assert_equal( 'This is it', 'this_is_it'.style(:humanize) )
  end

  def test_demodulize_01
    a =  "Down::Bottom"
    assert_equal( "Bottom", a.style(:demodulize) )
  end

  def test_demodulize_02
    b =  "Further::Down::Bottom"
    assert_equal( "Bottom", b.style(:demodulize) )
  end

  def test_demodulize_03
    assert_equal( "Unit", "Test::Unit".style(:demodulize) )
  end

  def test_modulize
    assert_equal( 'MyModule::MyClass',   'my_module__my_class'.style(:modulize)   )
    assert_equal( '::MyModule::MyClass', '__my_module__my_class'.style(:modulize) )
    assert_equal( 'MyModule::MyClass',   'my_module/my_class'.style(:modulize)    )
    assert_equal( '::MyModule::MyClass', '/my_module/my_class'.style(:modulize)   )
  end

  def test_methodize
    assert_equal( 'hello_world', 'HelloWorld'.style(:methodize) )
    assert_equal( '__unix_path', '/unix_path'.style(:methodize) )
  end

  def test_pathize
    assert_equal( 'my_module/my_class',   'MyModule::MyClass'.style(:pathize) )
    assert_equal( 'uri',                  'URI'.style(:pathize) )  # Hmm... this is reversible?
    assert_equal( '/my_class',            '::MyClass'.style(:pathize) )
    assert_equal( '/my_module/my_class/', '/my_module/my_class/'.style(:pathize) )
  end

end

