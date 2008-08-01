# Test for facets/advice.rb

require 'test/unit'
require 'facets/command'

include Console

class TC_Command_Simple < Test::Unit::TestCase

  #
  # Test simple, single funciton command.
  #

  class SimpleCommand < Command

    def call
      "hello"
    end

  end

  def test_simple
    assert_equal("hello", SimpleCommand.start)
  end

end

#
# Test dispatching commands (aka Master Commands).
#

class TC_Command_Dispatch < Test::Unit::TestCase

  class ComplexCommand < Command

    def sink
      "sink"
    end

    def swim
      "swim"
    end

  end

  def test_complex
    assert_equal("swim", ComplexCommand.start(['swim']))
  end

end

#
# Test subcommand convenience method.
#

class TC_Command_Subcommand < Test::Unit::TestCase

  class SubCommand < Command
    def call ; 'submarine' ; end
  end

  class ComplexCommand < Command
    subcommand :submariner, SubCommand
  end

  def test_complex
    assert_equal("submarine", ComplexCommand.start(['submariner']))
  end

end

