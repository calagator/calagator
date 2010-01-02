require 'net/http'
require 'uri'

module SuperExceptionNotifier
  module HooksNotifier
    # Deliver exception data hash to web hooks, if any
    #
    def self.deliver_exception_to_web_hooks(config, exception, controller, request, data={}, the_blamed = nil)
      params = build_web_hook_params(config, exception, controller, request, data, the_blamed)
      # TODO: use threads here
      config[:web_hooks].each do |address|
        post_hook(params, address)
      end
    end


    # Parameters hash based on Merb Exceptions example
    #
    def self.build_web_hook_params(config, exception, controller, request, data={}, the_blamed = nil)
      host = (request.env["HTTP_X_FORWARDED_HOST"] || request.env["HTTP_HOST"])
      p = {
        'environment'              => (defined?(Rails) ? Rails.env : RAILS_ENV),
        'exceptions'               => [{
          :class      => exception.class.to_s,
          :backtrace  => exception.backtrace,
          :message    => exception.message
          }],
        'app_name'                 => config[:app_name],
        'version'                  => config[:version],
        'blame'                    => "#{the_blamed}"
      }
      if !request.nil?
        p.merge!({'request_url'         => "#{request.protocol}#{host}#{request.request_uri}"})
        p.merge!({'request_action'      => request.parameters['action']})
        p.merge!({'request_params'      => request.parameters.inspect})
      end
      p.merge!({'request_controller'    => controller.class.name}) if !controller.nil?
      p.merge!({'status'                => exception.status}) if exception.respond_to?(:status)
      return p
    end

    def self.post_hook(params, address)
      uri = URI.parse(address)
      uri.path = '/' if uri.path=='' # set a path if one isn't provided to keep Net::HTTP happy

      headers = { 'Content-Type' => 'text/x-json' }
      data = params.to_json
      Net::HTTP.start(uri.host, uri.port) do |http|
        http.request_post(uri.path, data, headers)
      end
      data
    end

  end
end
