if SECRETS.default_url_host
  Calagator::Application.config.action_controller.default_url_options ||= {}
  Calagator::Application.config.action_controller.default_url_options.reverse_merge!( host: SECRETS.default_url_host )
end

