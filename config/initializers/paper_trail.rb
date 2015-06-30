# SerializedAttributes is deprecated in Rails 4.2.x, and will be removed in
#   Rails 5. PaperTrail spews a ton of deprecation warnings about this issue,
#   and while a fix for this issue is in their pending (as of 6/30/15) 4.0
#   release, this patch will silence the warning from clogging up Calagator test
#   runs.
#
#   More info: https://github.com/airblade/paper_trail/issues/416
#
# TODO: when Calagator uses PaperTrail 4.0 or higher, remove this initializer

if PaperTrail.version.to_f < 4.0
  current_behavior = ActiveSupport::Deprecation.behavior
  ActiveSupport::Deprecation.behavior = lambda do |message, callstack|
    return if message =~ /`serialized_attributes` is deprecated without replacement/ && callstack.any? { |m| m =~ /paper_trail/ }
    Array.wrap(current_behavior).each { |behavior| behavior.call(message, callstack) }
  end
else
  warn 'FIXME: PaperTrail initializer to suppress deprecation warnings can be safely removed.'
end
