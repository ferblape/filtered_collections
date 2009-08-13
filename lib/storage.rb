module FilteredCollections
  class Storage
    attr_reader :storage
    
    def initialize(storage=:lightcloud)
      case storage
      when :rails
        @storage = ::Rails.cache
      when :lightcloud
        @storage = load_lightcloud
      end          
    end
    
    def get(key)
      case self.storage.class.name
      when "ActiveSupport::Cache::MemCacheStore"
        self.storage.read(key)
      else
        YAML.load(self.storage.get(key) || '') || nil
      end
    end
    
    def set(key, value)
      case self.storage.class.name
      when "ActiveSupport::Cache::MemCacheStore"
        self.storage.write(key, value)
      else
        self.storage.set(key, YAML.dump(value || ''))
      end
    end
    
    def delete(key)
      self.storage.delete(key)
    end
    
    def method_missing(method_name, *args)
      self.storage.send(method_name, *args)
    end
    
    private
    def load_lightcloud
      require 'lightcloud'
      
      nodes_config = {}
      YAML.load_file("#{Rails.root}/config/lightcloud.yml")['nodes'].each do |name, values|
        nodes_config[name] = [values['host'], values['master']]
      end
      
      lookup_nodes, storage_nodes = LightCloud.generate_nodes(nodes_config)
      LightCloud.new(lookup_nodes, storage_nodes)
    end
  end
end