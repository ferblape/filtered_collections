require 'lightcloud'

$:.unshift File.dirname(__FILE__)

module FilteredCollections
  
  # Raised when the stored object hasn't attribute <tt>:id</tt>
  class MissingIdentifierAttribute < StandardError; end
  
  # Raised when the stored object hasn't the attribute indicated to order the collection
  class MissingSortByAttribute < StandardError; end
  
  # Raised when the arguments of a function are wrong
  class BadArguments < StandardError; end
  
  # FIXME
  # Defines the storage in which keep the collections. 
  # This has to be changed, in order to allow different storages (maybe with moneta project)
  class << self
  
    def storage
      @storage ||= begin
        nodes_config = {}
        YAML.load_file("#{Rails.root}/config/lightcloud.yml")['nodes'].each do |name, values|
          nodes_config[name] = [values['host'], values['master']]
        end
        lookup_nodes, storage_nodes = LightCloud.generate_nodes(nodes_config)
        LightCloud.new(lookup_nodes, storage_nodes)
      end
    end
    
  end
  
end

require 'lib/active_record_collection'
require 'lib/acts_as_stored_in_cache'
require 'lib/collection'
