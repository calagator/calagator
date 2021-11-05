# frozen_string_literal: true

PaperTrailManager.route_helpers = Calagator::Engine.routes.url_helpers
PaperTrailManager.base_controller = 'Calagator::ApplicationController'
PaperTrailManager.item_name_method = :title
