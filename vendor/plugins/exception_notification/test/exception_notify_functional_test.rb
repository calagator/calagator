require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require 'test/unit'

require File.join(File.dirname(__FILE__), 'mocks/controllers')

ActionController::Routing::Routes.clear!
ActionController::Routing::Routes.draw {|m| m.connect ':controller/:action/:id' }

class ExceptionNotifyFunctionalTest < ActionController::TestCase
  
  def setup
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new    
    ActionController::Base.consider_all_requests_local = false
    @@delivered_mail = []
    ActionMailer::Base.class_eval do
      def deliver!(mail = @mail)
        @@delivered_mail << mail
      end
    end    
  end

  def test_view_path_200; assert_view_path_for_status_cd_is_string("200"); end
  def test_view_path_400; assert_view_path_for_status_cd_is_string("400"); end
  def test_view_path_403; assert_view_path_for_status_cd_is_string("403"); end
  def test_view_path_404; assert_view_path_for_status_cd_is_string("404"); end
  def test_view_path_405; assert_view_path_for_status_cd_is_string("405"); end
  def test_view_path_410; assert_view_path_for_status_cd_is_string("410"); end
  def test_view_path_418; assert_view_path_for_status_cd_is_string("422"); end
  def test_view_path_422; assert_view_path_for_status_cd_is_string("422"); end
  def test_view_path_423; assert_view_path_for_status_cd_is_string("423"); end
  def test_view_path_500; assert_view_path_for_status_cd_is_string("500"); end
  def test_view_path_501; assert_view_path_for_status_cd_is_string("501"); end
  def test_view_path_503; assert_view_path_for_status_cd_is_string("503"); end
  def test_view_path_nil; assert_view_path_for_status_cd_is_string(nil); end
  def test_view_path_empty; assert_view_path_for_status_cd_is_string(""); end
  def test_view_path_nonsense; assert_view_path_for_status_cd_is_string("slartibartfarst"); end
  def test_view_path_class;
    exception = SuperExceptionNotifier::CustomExceptionClasses::MethodDisabled
    assert_view_path_for_class_is_string(exception);
    assert ExceptionNotifier.get_view_path_for_class(exception).match("/rails/app/views/exception_notifiable/method_disabled.html.erb")
  end
  def test_view_path_class_nil; assert_view_path_for_class_is_string(nil); end
  def test_view_path_class_empty; assert_view_path_for_class_is_string(""); end
  def test_view_path_class_nonsense; assert_view_path_for_class_is_string("slartibartfarst"); end
  def test_view_path_class_integer; assert_view_path_for_class_is_string(Integer); end

  def test_exception_to_filenames
    assert(["super_exception_notifier_custom_exception_classes_method_disabled", "method_disabled"] == ExceptionNotifier.exception_to_filenames(SuperExceptionNotifier::CustomExceptionClasses::MethodDisabled))
  end

  def test_old_style_where_requests_are_local
    ActionController::Base.consider_all_requests_local = true
    @controller = OldStyle.new
    get "runtime_error"    
    assert_nothing_mailed
  end

  def test_new_style_where_requests_are_local
    ActionController::Base.consider_all_requests_local = true
    @controller = NewStyle.new
    ExceptionNotifier.config[:skip_local_notification] = true
    get "runtime_error"
    assert_nothing_mailed
  end
  
  def test_old_style_runtime_error_sends_mail
    @controller = OldStyle.new
    get "runtime_error"
    assert_error_mail_contains("This is a runtime error that we should be emailed about")
  end
  
  def test_old_style_record_not_found_does_not_send_mail
    @controller = OldStyle.new
    get "ar_record_not_found"
    assert_nothing_mailed
  end
  
  def test_new_style_runtime_error_sends_mail
    @controller = NewStyle.new
    get "runtime_error"
    assert_error_mail_contains("This is a runtime error that we should be emailed about")    
  end
  
  def test_new_style_record_not_found_does_not_send_mail
    @controller = NewStyle.new
    get "ar_record_not_found"    
    assert_nothing_mailed
  end

  def test_controller_with_custom_silent_exceptions
    @controller = CustomSilentExceptions.new
    get "runtime_error"
    assert_nothing_mailed
  end

  def test_controller_with_empty_silent_exceptions
    @controller = EmptySilentExceptions.new
    get "ar_record_not_found"
    assert_error_mail_contains("ActiveRecord::RecordNotFound")
  end

  def test_controller_with_nil_silent_exceptions
    @controller = NilSilentExceptions.new
    get "ar_record_not_found"
    assert_error_mail_contains("ActiveRecord::RecordNotFound")
  end

  def test_controller_with_default_silent_exceptions
    @controller = DefaultSilentExceptions.new
    get "unknown_controller"
    assert_nothing_mailed
  end

  private

  def assert_view_path_for_status_cd_is_string(status)
    assert(ExceptionNotifier.get_view_path_for_status_code(status).is_a?(String), "View Path is not a string for status code '#{status}'")
  end

  def assert_view_path_for_class_is_string(exception)
    assert(ExceptionNotifier.get_view_path_for_class(exception).is_a?(String), "View Path is not a string for exception '#{exception}'")
  end

  def assert_error_mail_contains(text)
    assert(mailed_error.index(text), 
          "Expected mailed error body to contain '#{text}', but not found. \n actual contents: \n#{mailed_error}")
  end
  
  def assert_nothing_mailed
    assert @@delivered_mail.empty?, "Expected to have NOT mailed out a notification about an error occuring, but mailed: \n#{@@delivered_mail}"
  end
  
  def mailed_error
    assert @@delivered_mail.last, "Expected to have mailed out a notification about an error occuring, but none mailed"
    @@delivered_mail.last.encoded
  end
  
end
