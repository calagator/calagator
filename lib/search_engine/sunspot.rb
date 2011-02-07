require 'lib/search_engine/base'

class SearchEngine::Sunspot < SearchEngine::Base
  score true
end

# Monkeypatch Sunspot to connect to Solr server. Sigh. For details, see:
# http://groups.google.com/group/ruby-sunspot/browse_thread/thread/34772773b4b5682d
module Sunspot::Rails
  def slave_config(sunspot_rails_configuration)
    config = Sunspot::Configuration.build
    config.solr.url = URI::HTTP.build(
        :host => sunspot_rails_configuration.hostname,
        :port => sunspot_rails_configuration.port,
        :path => sunspot_rails_configuration.path
      ).to_s
    config
  end
end
Sunspot.session = Sunspot::Rails.build_session
