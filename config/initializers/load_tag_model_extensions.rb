require "acts-as-taggable-on"
require "tag_model_extensions"
ActsAsTaggableOn::Tag.send :include, TagModelExtensions
