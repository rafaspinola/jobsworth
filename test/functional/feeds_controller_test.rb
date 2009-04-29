require File.dirname(__FILE__) + '/../test_helper'

class FeedsControllerTest < ActionController::TestCase
  fixtures :users
  
  def setup 
    @request.host = 'cit.local.host'
  end
  
  test "should not redirect to login" do
    get :rss, { :id => '1234567890abcdefghijklmnopqrstuv'}
  end 
  
  test "should be able to unsubscribe" do 
    user = User.find_by_uuid('1234567890abcdefghijklmnopqrstuv')
    assert_equal 1, user.newsletter
    get :unsubscribe, { :id => '1234567890abcdefghijklmnopqrstuv'}
    unsubbed = User.find_by_uuid('1234567890abcdefghijklmnopqrstuv')
    assert_equal 0, unsubbed.newsletter
    assert_response :success
    assert @response.body.index("unsubscribed")
  end

#   xtest "should get RSS"
  
#   xtest "should get iCal"
  
#   xtest "should get iGoogle widget"
end 
