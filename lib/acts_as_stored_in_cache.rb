module FilteredCollections
  module ActsAsStoredInCache
  
    def self.included(base)
      base.extend(ClassMethods)  
    end
  
    module ClassMethods
      def acts_as_stored_in_cache
        
        after_save :store_in_cache
        after_destroy :delete_from_cache
        
        class << self
          def stored_in_cache; true end
        end
        
        include FilteredCollections::ActsAsStoredInCache::InstanceMethods
      end
      
      def cache_key( id )
        "#{self.to_s.underscore}/#{id}"
      end
      
      def load( id )
        if obj = ::Rails.cache.read( self.cache_key(id) ) 
          Marshal.load(YAML.load(obj))
        else
          find_by_id(id)
        end
      end
      
      def load_collection( ids )
        ids.map { |id| load( id ) }
      end
      
    end
  
    module InstanceMethods
      
      
      def cache_key
        self.class.cache_key( self.id )
      end
      
      def store_in_cache
        ::Rails.cache.write(self.cache_key, Marshal.dump(self.reload).to_yaml)
      end

      def delete_from_cache
        ::Rails.cache.delete(self.cache_key)
      end
        
    end
    
  end
  
end

ActiveRecord::Base.send(:include, FilteredCollections::ActsAsStoredInCache)