require File.dirname(__FILE__) + '/test_helper'
require 'action_controller/test_process'

class ExceptionNotifierTest < Test::Unit::TestCase
  
  def setup
    @controller = ActionController::Base.new
    @controller.request = ActionController::TestRequest.new
    @controller.response = ActionController::TestResponse.new
    @controller.params = {}
    @controller.send(:initialize_current_url)
    ActionController::Base.consider_all_requests_local = false
    @@delivered_mail = []
    ActionMailer::Base.class_eval do
      def deliver!(mail = @mail)
        @@delivered_mail << mail
      end
    end
  end

  def test_should_generate_message_without_controller
    begin
      raise 'problem'
    rescue RuntimeError => e
      assert_nothing_raised do
        ExceptionNotifier.deliver_exception_notification(e)
      end
    end
  end

  def test_should_generate_message_with_controller
    begin
      raise 'problem'
    rescue RuntimeError => e
      assert_nothing_raised do
        ExceptionNotifier.deliver_exception_notification(e, @controller, @controller.request)
      end
    end
  end

end
