# manage_cache

Define cache_keys to be deleted before save or destroy in the model.

This is especially usefull for all cache stores other than memcached, but can help that cached content is not thrown away just because of a full memory when using memcached as well.

Another advantage is that it is not necessary to touch relations. Just define the cache_key right.

NOTE: regexp was buggy with redis! Use version 0.0.5!

# Usage

Add the gem to your Gemfile:

```ruby
gem 'manage_cache', '~> 0.0.5'
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

NOTES: 
+ You have to use `skip_digest: true` and none of the other options to the cache helper.
With low-level caching (e.g. `Rails.cache.fetch(@some_class.cache_key_for(:some_key) { cached content }` everything works as expected.
+ It is not necessary to include updated_at in the cache_key because cache will be deleted on update. It does not need to be invalidated via an updated cache_key. This might save some db-queries. 

# Examples

+ The easiest case would be a simple :show -page e.g.: 

   ```ruby
   class User < ActiveRecord::Base
     has_many :shoes
     manage_cache_for user_show: { instance_eval: { user: :id }
   end
   ```

   ```erb
   <% cache user.cache_key_for(:user_show), skip_digest: true do %>
        ....
   <% end %>
   ```

   `user.cache_key_for(:user_show)` in this case would be: "spec=user_show-user=someid"

+ A cache which should be deleted either on change of some attribute in one model or on change of another attribute in another model would be written, e.g.:

   ```ruby
   class Shoe < ActiveRecord::Base
     belongs_to :user
     manage_cache_for users_shoes: { instance_eval: { user: "user.id" }, if_changed: [:color] }
   end
   
   class User < ActiveRecord::Base
     has_many :shoes
     manage_cache_for users_shoes: { instance_eval: { user: :id }, if_changed: [:name] }
   end
   ```

   ```erb
   <% cache @user.cache_key_for(:users_shoes), skip_digest: true do %>
     <%= @user.name %>
     <% @user.shoes.each do |shoe| %>
       <%= "#{shoe.name}: #{shoe.color}" %>
     <% end %>
   <% end %>
   ```
   So, the cache for a users` shoes would be deleted if either the color of one of his shoes or his name changes.

+ Regexp can be used for e.g. paginated content:

   ```
   class User < ActiveRecord::Base
     manage_cache_for users_index: { regexp: { page: "\\d+" } }
   end
   ```
   NOTE: The quoted regexp part: `"\\d+"` instead of `"\d+"` necessary for FileStore!! Using RedisStore all the expressions will be replaced with `*`.  

   This would delete all pages cached with the following:

   ```erb
   <% cache @users.first.try(:cache_key_for, :users_index, page: params[:page] || 1), skip_digest: true do %>
     ...
   <% end %>
   ```
   
   NOTES:
   +  use `@collection.first.try(:cache_key_for, :...)` on collections. They might be empty!
   + use `page: params[:page] || 1` because the first page is normally called without params[:page] - this content would    never be deleted!
   + memcached does not implent `delete_matched` therefore regexp cannot be used with memcached. 
   + If cache_store is redis_store patterns like `\d+` will be replaced with `*`. Note as well that Redis has performance problems regexp-ing keys [redis-store/issues/186](https://github.com/redis-store/redis-store/issues/186).

