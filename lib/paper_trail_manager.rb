# frozen_string_literal: true

require 'rails'
require 'paper_trail'

begin
  require 'will_paginate'
rescue LoadError
  begin
    require 'kaminari'
  rescue LoadError
    raise LoadError, 'will_paginate or kaminari must be in Gemfile or load_path'
  end
end

class PaperTrailManager < Rails::Engine
  initializer 'paper_trail_manager.pagination' do
    ::ActionView::Base.send(:alias_method, :paginate, :will_paginate) if defined?(WillPaginate)
  end

  @@whodunnit_name_method = :name
  cattr_accessor :whodunnit_class, :whodunnit_name_method, :route_helpers,
                 :layout, :base_controller, :user_path_method, :item_name_method

  self.base_controller = 'ApplicationController'
  self.user_path_method = :user_path

  (Pathname(__FILE__).dirname + '..').tap do |base|
    paths['app/controller'] = base + 'app/controllers'
    paths['app/view'] = base + 'app/views'
  end

  cattr_accessor :allow_index_block, :allow_show_block, :allow_revert_block

  block = proc { true }
  self.allow_index_block = block
  self.allow_show_block = block
  self.allow_revert_block = block

  def self.allow_index_when(&block)
    self.allow_index_block = block
  end

  def self.allow_index?(controller)
    allow_index_block.call controller
  end

  def self.allow_show_when(&block)
    self.allow_show_block = block
  end

  def self.allow_show?(controller, version)
    allow_index_block.call controller, version
  end

  # Describe when to allow reverts. Call this with a block that accepts
  # arguments for +controller+ and +version+.
  def self.allow_revert_when(&block)
    self.allow_revert_block = block
  end

  # Allow revert given the +controller+ and +version+? If no
  # ::allow_revert_when was specified, always return +true+.
  def self.allow_revert?(controller, version)
    allow_revert_block.call controller, version
  end
end
