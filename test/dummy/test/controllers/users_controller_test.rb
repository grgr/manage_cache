require 'test_helper'

class UsersControllerTest < ActionController::TestCase

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

  test "users#show cache should be updated after user update" do
    get :show, {id: @hans.id}
    old_cache_key = @hans.cache_key_for(:show)
    assert_match(/Hans/, Rails.cache.read("views/#{old_cache_key}"))

    sleep 1
    @hans.update(name: 'Peter')
    assert_nil(Rails.cache.read("views/#{old_cache_key}"))
    assert_nil(@hans.instance_variable_get("@cache_key_for_show"))
    new_cache_key = @hans.cache_key_for(:show)
    assert_not_equal(new_cache_key, old_cache_key)
    assert_not_nil(@hans.instance_variable_get("@cache_key_for_show"))

    get :show, {id: @hans.id}
    assert_match(/Peter/, Rails.cache.read("views/#{new_cache_key}"))
  end  


  test "users#index row_name-cache should be updated after user update" do
    get :index
    assert_match(/is Hans/, Rails.cache.read("views/#{@hans.cache_key_for(:row_name)}"))

    @hans.update(name: 'Peter')
    assert_nil(Rails.cache.read("views/#{@hans.cache_key_for(:row_name)}"))

    get :index
    assert_match(/is Peter/, Rails.cache.read("views/#{@hans.cache_key_for(:row_name)}"))
    get :index
  end  


  test "users#index users_shoes-cache should be updated after user update" do
    get :index
    assert_match(/Puma: red/, Rails.cache.read("views/#{@hans.shoes.last.try(:cache_key_for, :users_shoes)}"))

    @puma.update(color: 'violet')
    assert_nil(Rails.cache.read("views/#{@hans.shoes.last.try(:cache_key_for, :users_shoes)}"))

    get :index
    assert_match(/Puma: violet/, Rails.cache.read("views/#{@hans.shoes.last.try(:cache_key_for, :users_shoes)}"))
  end  
end
