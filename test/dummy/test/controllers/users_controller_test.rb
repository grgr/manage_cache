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

    Rails.cache.clear
  end

  def teardown
    Rails.cache.clear
  end

  test "users#show cache should be updated after user update" do
    get :show, {id: @hans.id}
    assert_match(/Hans/, Rails.cache.read("views/#{@hans.cache_key_for(:show)}"))

    @hans.update(name: 'Peter')
    assert_nil(Rails.cache.read("views/#{@hans.cache_key_for(:show)}"))

    get :show, {id: @hans.id}
    assert_match(/Peter/, Rails.cache.read("views/#{@hans.cache_key_for(:show)}"))
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
