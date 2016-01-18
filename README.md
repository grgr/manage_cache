# manage_cache

Define cache_keys to be deleted after save or destroy in the model.

This is especially usefull for all cache stores other than memcached, but can help that cached content is not thrown away just because of a full memory when using memcached as well.

Another advantage is that it is not necessary to touch relations. Just define the cache_key right.

NOTE: This Readme is updated for version 0.0.3.

# Usage

Add the gem to your Gemfile:

```ruby
gem 'manage_cache', '~> 0.0.2'
```

In your ActiveRecord model, write e.g.:

```ruby
class SomeClass < ActiveRecord::Base
  manage_cache_for some_key: { instance_eval: { some_class: :id, another_method_key: :another_method } }
end
```
Values used in the specified cache_key (here: some_key) are:
+ static: a hash with free static values to be included to the cache_key
+ instance_eval: a hash with keys being free and values being instance_evaled
+ class_eval: a hash with keys being free and values being class_evaled
+ regexp: a hash where keys should match keys of opts given to cache_key_for and values being the regexp-part to match against (see examples below).
+ if_changed: an Array specifying the attributes which have to be changed to delete this cache. Note: updated_at does not count here. Just don\`t specify :if_changed if you want the cache to be deleted on updated_at/ on every save. 

In the view you can than:

```erb
<% cache @some_class.cache_key_for(:some_key), skip_digest: true do %>
  Some Content to be cached.
<% end %>
```

NOTICE: you have to use `skip_digest: true` and none of the other options to the cache helper.
With low-level caching (e.g. `Rails.cache.fetch(@some_class.cache_key_for(:some_key) { cached content }` everything works as expected.

# Example

The easiest case would be updated_at e.g.: 

```ruby
class User < ActiveRecord::Base
  has_many :shoes
  manage_cache_for show: { instance_eval: { user: :id }
end
```

A slightly more complicated one would be (using the User model above as well):
```ruby
class Shoe < ActiveRecord::Base
  belongs_to :user
  manage_cache_for users_shoes: { instance_eval: { user: "user.id", last_updated_shoe: "user.shoes.maximum(:updated_at)" } }
end
```


The above cache_key could be used somewhere where the user`s shoes are shown e.g. :show or :index e.g.:

```erb
<% cache user.shoes.last.try(:cache_key_for, :users_shoes), skip_digest: true do %>
     ....
<% end %>
```

It is enough to take any of the users\` shoes for the cache_key here because it will write the user\`s id 
and the last updated shoe into the cache_key.
