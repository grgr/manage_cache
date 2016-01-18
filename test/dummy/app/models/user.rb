class User < ActiveRecord::Base

  has_many :shoes

  manage_cache_for show: { instance_eval: { user: :id, updated_at: :updated_at } },
    row_name: { instance_eval: { user: :id, updated_at: :updated_at } },
    users_index: { class_eval: { max_up: "maximum(:updated_at)"} }

  def nice_name
    "nice name is #{name}"
  end
end
