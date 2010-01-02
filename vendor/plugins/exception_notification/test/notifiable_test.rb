# This is to test the ability to handle exceptions raised outside of the request response cycle
require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require 'test/unit'

class Spaceship
  # It is included by the init.rb in the Object super class,
  #   so we don't actually need to do anything to get notifiable { method } goodness.
  #include Notifiable
end

class SpaceCarrier < Spaceship
end

class NotifiableTest < Test::Unit::TestCase

  def setup
    @@delivered_mail = []
    ActionMailer::Base.class_eval do
      def deliver!(mail = @mail)
        @@delivered_mail << mail
      end
    end
  end

  def test_notifiable_in_noisy_environment
    @class = Spaceship.new
    Spaceship.notifiable_noisy_environments = ['test']
    ExceptionNotifier.config[:skip_local_notification] = true
    assert_raises( AccessDenied ) {
      notifiable { @class.access_denied }
      assert_error_mail_contains("AccessDenied")
    }
  end

  def test_notifiable_in_quiet_environment_not_skipping_local
    @class = Spaceship.new
    Spaceship.notifiable_noisy_environments = []
    ExceptionNotifier.config[:skip_local_notification] = false
    assert_raises( AccessDenied ) {
      notifiable { @class.access_denied }
      assert_error_mail_contains("AccessDenied")
    }
  end

  def test_notifiable_in_quiet_environment_skipping_local
    @class = Spaceship.new
    Spaceship.notifiable_noisy_environments = []
    ExceptionNotifier.config[:skip_local_notification] = true
    assert_raises( AccessDenied ) {
      notifiable { @class.access_denied }
      assert_nothing_mailed
    }
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
