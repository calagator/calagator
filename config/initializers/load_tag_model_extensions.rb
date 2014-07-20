require "tag_model_extensions"
ActsAsTaggableOn::Tag.send :include, TagModelExtensions
