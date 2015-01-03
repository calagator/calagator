# Setup exception notification, if necessary
if ENV['NOTIFY_ON_EXCEPTIONS'] || %w[preview production].include?(Rails.env)
  # Make all requests appear non-local, so the production-style error page is displayed.
  class ActionDispatch::Request
    def local?
     false
    end
  end

  Calagator::Application.config.middleware.use ExceptionNotifier,
    :email_prefix => "[ERROR #{SETTINGS.name}] ",
    :sender_address => "#{ENV['administrator_email']}",
    :exception_recipients => [ENV['administrator_email']]
end
