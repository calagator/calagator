require File.dirname(__FILE__) + '/test_helper'

class ExceptionNotifiableTest < Test::Unit::TestCase

  def setup
    @controller = BasicController.new
  end

  #Tests for the default values when ExceptionNotifiable is included in a controller
  def test_default_http_status_codes
    assert(BasicController.http_status_codes == HTTP_STATUS_CODES, "Default http_status_codes is incorrect")
  end

  def test_default_error_layout
    assert(BasicController.error_layout == nil, "Default error_layout is incorrect")
  end

  def test_default_error_class_status_codes
    assert(BasicController.error_class_status_codes == BasicController.codes_for_error_classes, "Default error_class_status_codes is incorrect")
  end

  def test_default_exception_notifiable_verbose
    assert(BasicController.exception_notifiable_verbose == false, "Default exception_notifiable_verbose is incorrect")
  end

  def test_default_exception_notifiable_silent_exceptions
    assert(BasicController.exception_notifiable_silent_exceptions == SILENT_EXCEPTIONS, "Default exception_notifiable_silent_exceptions is incorrect")
  end

  def test_default_exception_notifiable_notification_level
    assert(BasicController.exception_notifiable_notification_level == [:render, :email, :web_hooks], "Default exception_notifiable_notification_level is incorrect")
  end

end
