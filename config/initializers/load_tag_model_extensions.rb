require "acts-as-taggable-on"
require "calagator/tag_model_extensions"
ActsAsTaggableOn::Tag.send :include, Calagator::TagModelExtensions
