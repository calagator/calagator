require "acts-as-taggable-on"
require "calagator/machine_tag"
ActsAsTaggableOn::Tag.send :include, Calagator::MachineTag::TagExtensions
