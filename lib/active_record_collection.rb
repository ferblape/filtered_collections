module FilteredCollections
  module ActiveRecordCollection
  
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
    end
  
    module ClassMethods
    
      def has_collection( collection_name, options = {} )
        define_method collection_name.to_sym do
          eval(collection_name.to_s.camelize.constantize.builder(options))
        end
      end
      
    end
  
  end
end

ActiveRecord::Base.send(:include, FilteredCollections::ActiveRecordCollection)