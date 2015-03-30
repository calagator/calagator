module DomEquivalence
  extend RSpec::Matchers::DSL

  matcher :match_dom_of do |target|
    match_unless_raises ActiveSupport::TestCase::Assertion do |source|
      assert_dom_equal source, target
    end

    failure_message_for_should do |source|
      "Expected #{source} to have equivalent DOM to #{target}"
    end

    failure_message_for_should_not do |source|
      "Expected #{source} not to have equivalent DOM to #{target}"
    end

    description do
      "should be DOM equivalent to #{target}"
    end
  end
end


class RSpec::Core::ExampleGroup
  include DomEquivalence
end
