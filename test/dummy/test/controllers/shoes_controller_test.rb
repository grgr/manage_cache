require 'test_helper'

class ShoesControllerTest < ActionController::TestCase

  def setup
    # fixtures not working :(
    #@hans = users(:hans)
    @hans  = User.create(name: 'Hans')
    @xaver = User.create(name: 'Xaver')

    @puma = Shoe.create(name: 'Puma', color: 'red',  user_id: @hans.id)
    @nike = Shoe.create(name: 'Nike', color: 'blue', user_id: @hans.id)
    @saucony = Shoe.create(name: 'Saucony', color: 'yellow', user_id: @hans.id)

    #Rails.cache.clear
  end

  def teardown
    #Rails.cache.clear
  end


  test "shoes#index -cache should be updated after shoe update" do
    get :index, page: 1
    assert_not_nil(Rails.cache.read("views/#{@puma.cache_key_for(:shoes_index, page: 1)}"))

    # without this sleep cache won`t be deleted in the next assertion
    sleep 1
    @puma.update_attribute(:color, 'violet')
    assert_nil(Rails.cache.read("views/#{@puma.cache_key_for(:shoes_index, page: 1)}"))
  end  
end
