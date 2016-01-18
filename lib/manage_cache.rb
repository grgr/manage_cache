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

      before_save    { |record| record.dump_cache! }
      before_destroy { |record| record.dump_cache! }

      include ManageCache::LocalInstanceMethods
    end
  end

  module LocalInstanceMethods
    def dump_cache!
      self.class.cache_keys_specs.each do |key_name, key_specs|
        # the rails helper method 'cache (name, opts) do ...'
        # adds some extras to the cache key.
        # To run with this gem, you have to add 'skip_digest: true'.
        # Any other options will prevent correct cache deletion!!
        #
        [cache_key_for(key_name), "views/#{cache_key_for(key_name)}"].each do |key|
          #
          # Opts added to cache_key_for will be suffixed to the rest of 
          # the cache_key.
          # For these opts to take effect on cache management (e.g. deletion)
          # use `regexp: { opts_key: "matcher_string" , .... } 
          # e.g.:
          #
          # in the paginated index view:
          #
          #   <% cache @users.last.try(:cache_key_for, :users_index, page: params[:page]) do %>
          #
          # in the model:
          #
          #   class User < ActiveRecord::Base
          #     manage_cache_for users_index: { 
          #                        class_eval: { max_up: "maximum(:updated_at)"} 
          #                        regexp:     { page: "\d+" }
          #                      }
          #
          if !key_specs[:regexp].blank?
            delete_cache_w_regexp(key, key_specs)
          else
            Rails.cache.delete(key)
          end
          instance_variable_set("@cache_key_for_#{key_name}", nil)
        end
      end
    end

    def cache_key_for(spec, opts={})
      instance_variable_get("@cache_key_for_#{spec}") ||
        instance_variable_set("@cache_key_for_#{spec}", prepare_cache_key(spec, opts))
    end

    private
     
    def prepare_cache_key(spec, opts={})
      cache_key = {}

      key_specs = self.class.cache_keys_specs[spec]

      if key_specs.blank?
        raise "The specification for cache_key '#{spec}' is missing in manage_cache in #{self.class.name}."
      end

      # some extra specification like :show or :index_row
      # defaults to the spec-key
      #
      cache_key[:spec] = spec

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
      #  <% cache user.shoes.last.try(:cache_key_for, :users_shoes), skip_digest: true do %>
      #    ....
      #
      # it is enough to take one of the users` shoes for the cache_key here
      # because it will write the user`s id 
      # and the last updated shoe into the cache_key
      #
      key_specs[:instance_eval].each do |name, cmd| 
        cache_key[name] = self.instance_eval(cmd.to_s)
      end if key_specs[:instance_eval]
      
      key_specs[:class_eval].each do |name, cmd| 
        cache_key[name] = self.class.class_eval(cmd.to_s)
      end if key_specs[:class_eval]


      # merge static values from manage_cache_for sth: { static: 'static' }
      #
      # and opts from cache_key_for, like:
      #   <% cache cache_key_for(:sth, page: params[:page]) %>
      #
      [key_specs[:static], opts].each do |hash|
        cache_key.reverse_merge!(hash) if hash
      end

      cache_key.inject([]){ |mem, (k,v)| mem << "#{k}=#{v}" }.join('-')
    end

    def delete_cache_w_regexp(key, specs)
      regexp = specs[:regexp].inject([]){|m, (k,v)| m << "#{k}=#{v}" }.join('-')
      Rails.cache.delete_matched(/^#{Regexp.escape(key)}-#{regexp}$/)
    end
  end
end

ActiveRecord::Base.send :include, ManageCache
