class Shoe < ActiveRecord::Base

  belongs_to :user
  validates :user_id, presence: true

  manage_cache_for users_shoes: { instance_eval: { user: "user.id", last_updated_shoe: "user.shoes.maximum(:updated_at)" } },
    users_index: { instance_eval: { max_up: "user.class.maximum(:updated_at)"} },
    shoes_index: { class_eval: { max_up: "maximum(:updated_at)" }, regexp: { page: "\\d*" } }


  def name_with_color
    "#{name}: #{color}"
  end
end
