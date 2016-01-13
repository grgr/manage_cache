module ManageCache
  extend ActiveSupport::Concern
   
  included do
  end

  module ClassMethods
    def manage_cache_for(keys_specs={})
      #
      # cache_keys_specs is an Array of Hashes, each specifying one cache_key
      # see prepare_cache_key-method below for options to be used
      #
      cattr_accessor :cache_keys_specs
      self.cache_keys_specs = keys_specs

      after_save     { |record| record.dump_cache! }
      before_destroy { |record| record.dump_cache! }

      include ManageCache::LocalInstanceMethods
    end
  end

  module LocalInstanceMethods
    def dump_cache!
      self.class.cache_keys_specs.each do |k,v|
        instance_variable_set("@cache_key_for_#{k}", nil)

        # the rails helper method 'cache (name, opts) do ...'
        # adds some extras to the cache key.
        # To run with this gem, you have to add 'skip_digest: true'.
        # Any other options will prevent correct cache deletion!!
        #
        [cache_key_for(k), "views/#{cache_key_for(k)}"].each do |key|
          Rails.cache.delete(key)
        end
      end
    end

    def cache_key_for(spec)
      instance_variable_get("@cache_key_for_#{spec}") ||
        instance_variable_set("@cache_key_for_#{spec}", prepare_cache_key(spec))
    end

    private
     
    def prepare_cache_key(spec)
      cache_key = {}

      key_specs = self.class.cache_keys_specs[spec]

      # some extra specification like :show or :index_row
      # defaults to the spec-key
      #
      cache_key[:spec] = key_specs[:spec] || spec

      # named values from some method calls
      # the easiest case would be updated_at e.g.: 
      #
      #   class User < ActiveRecord::Base
      #     manage_cache_for user_updated_at: { instance_eval: { user: :id, updated_at: :updated_at }
      #
      # a slightly more complicated one would be:
      # imagine following models: 
      #   User: has_many :shoes
      #   Shoe: belongs_to :user
      #
      # so in the Shoe model there would be:
      #
      #   class Shoe < ActiveRecord::Base
      #     belongs_to :user
      #     manage_cache_for users_shoes: { instance_eval: { user: "user.id", last_updated_shoe: "user.shoes.maximum(:updated_at)" } }
      #
      # and this cache_key could be used somewhere where the user`s shoes are shown e.g. :show or :index
      #
      #  e.g. 
      #  <% cache user.shoes.last.try.cache_key_for(:users_shoes), skip_digest: true do %>
      #    ....
      #
      # it is enough to take one of the users` shoes for the cache_key here
      # because it will write the user`s id 
      # and the last updated shoe into the cache_key
      #
      key_specs[:instance_eval].each do |name, cmd| 
        cache_key[name] = self.instance_eval(cmd.to_s)
      end
      
      cache_key.inject([]){ |mem, (k,v)| mem << "#{k}-#{v}" }.join('/')
    end

  end
end

ActiveRecord::Base.send :include, ManageCache
