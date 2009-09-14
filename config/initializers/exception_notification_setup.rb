require 'etc'
require 'socket'

ExceptionNotifier.exception_recipients = [SECRETS.administrator_email]
ExceptionNotifier.email_prefix = "[ERROR #{SETTINGS.name}] "
ExceptionNotifier.sender_address = "#{Etc.getlogin}@#{Socket.gethostname}"
