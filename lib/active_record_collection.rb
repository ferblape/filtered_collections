module FilteredCollections
  module ActiveRecordCollection
  
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
    end
  
    module ClassMethods
    
      # TODO
      # def has_collection( collection_name )
      #   define_method collection_name.to_sym do
      #     puts "collection_name: #{collection_name.camelize}"
      #   end
      # end
      
    end
  
  end
end

ActiveRecord::Base.send(:include, FilteredCollections::ActiveRecordCollection)