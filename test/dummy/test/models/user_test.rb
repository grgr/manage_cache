require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def setup
    #@user = users(:hans)
    @user = User.create(name: 'Hans')
  end

  test "cache_key_for should return the right key" do
    assert_equal @user.cache_key_for(:show), {spec: :show, user: @user.id, updated_at: @user.updated_at}.inject([]){ |mem, (k,v)| mem << "#{k}=#{v}" }.join('-') 
  end

end
