require 'test_helper'

class ShoeTest < ActiveSupport::TestCase

  def setup
    @user = User.create(name: :hans)
    @shoe = Shoe.create(name: 'Puma', color: 'red', user_id: @user.id)
  end

  test "cache will be deleted if specified attribute changed" do
    Rails.cache.write @shoe.cache_key_for(:shoe_color), @shoe.color
    assert_equal @shoe.color, Rails.cache.read(@shoe.cache_key_for(:shoe_color))
    @shoe.update color: 'blue'
    assert_nil Rails.cache.read @shoe.cache_key_for(:shoe_color)
  end
  test "cache will not be deleted if specified attribute did not change" do
    Rails.cache.write @shoe.cache_key_for(:shoe_color), @shoe.color
    assert_equal @shoe.color, Rails.cache.read(@shoe.cache_key_for(:shoe_color))
    @shoe.update name: 'Nike'
    assert_equal @shoe.color, Rails.cache.read(@shoe.cache_key_for(:shoe_color))
  end
end
