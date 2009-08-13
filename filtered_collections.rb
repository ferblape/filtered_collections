require 'lightcloud'

$:.unshift File.dirname(__FILE__)

module FilteredCollections
  
  class CollectionIdRequired < StandardError; end
  class CollectionBelongsToRequired < StandardError; end
  
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
