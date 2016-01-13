# manage_cache

Define cache_keys to be deleted after save or destroy in the model.

This is especially usefull for all cache stores other than memcached, but can help that cached content is not thrown away just because of a full memory when using memcached as well.

Another advantage is that it is not necessary to touch relations. Just define the cache_key right.

# Usage

Add the gem to your Gemfile:

```ruby
gem 'mamage_cache', git: 'git://github.com/grgr/manage_cache.git'
```
