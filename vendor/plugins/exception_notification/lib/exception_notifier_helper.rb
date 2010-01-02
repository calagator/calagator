require 'pp'

module ExceptionNotifierHelper
  VIEW_PATH = "views/exception_notifier" unless defined?(VIEW_PATH)
  APP_PATH = "#{RAILS_ROOT}/app/#{VIEW_PATH}" unless defined?(APP_PATH)
  PARAM_FILTER_REPLACEMENT = "[FILTERED]" unless defined?(PARAM_FILTER_REPLACEMENT)
  COMPAT_MODE = defined?(RAILS_GEM_VERSION) ? RAILS_GEM_VERSION < '2' : false unless defined?(COMPAT_MODE)

  def render_section(section)
    RAILS_DEFAULT_LOGGER.info("rendering section #{section.inspect}")
    summary = render_overridable(section).strip
    unless summary.blank?
      title = render_overridable(:title, :locals => { :title => section }).strip
      "#{title}\n\n#{summary.gsub(/^/, "  ")}\n\n"
    end
  end

  def render_overridable(partial, options={})
    if File.exist?(path = "#{APP_PATH}/_#{partial}.html.erb") ||
        File.exist?(path = "#{File.dirname(__FILE__)}/../#{VIEW_PATH}/_#{partial}.html.erb") ||
        File.exist?(path = "#{APP_PATH}/_#{partial}.rhtml") ||
        File.exist?(path = "#{APP_PATH}/_#{partial}.erb")
      render(options.merge(:file => path, :use_full_path => false))
    else
      ""
    end
  end

  def inspect_model_object(model, locals={})
    render_overridable(:inspect_model,
      :locals => { :inspect_model => model,
                   :show_instance_variables => true,
                   :show_attributes => true }.merge(locals))
  end

  def inspect_value(value)
    len = 512
    result = object_to_yaml(value).gsub(/\n/, "\n  ").strip
    result = result[0,len] + "... (#{result.length-len} bytes more)" if result.length > len+20
    result
  end

  def object_to_yaml(object)
    object.to_yaml.sub(/^---\s*/m, "")
  end

  def exclude_raw_post_parameters?
    @controller && @controller.respond_to?(:filter_parameters)
  end

  def filter_sensitive_post_data_parameters(parameters)
    exclude_raw_post_parameters? ? COMPAT_MODE ? @controller.filter_parameters(parameters) : @controller.__send__(:filter_parameters, parameters) : parameters
  end

  def filter_sensitive_post_data_from_env(env_key, env_value)
    return env_value unless exclude_raw_post_parameters?
    return PARAM_FILTER_REPLACEMENT if (env_key =~ /RAW_POST_DATA/i)
    return COMPAT_MODE ? @controller.filter_parameters({env_key => env_value}).values[0] : @controller.__send__(:filter_parameters, {env_key => env_value}).values[0]
  end
end
