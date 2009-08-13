module FilteredCollections
  
  class FakeStorage
    
    def initialize
      @memory = {}
    end

    def get(key)
      @memory[key] 
    end

    def set(key, value)
      @memory[key] = value
    end
    
    def reset
      @memory.each { |k,v| @memory[k] = nil }
    end

  end
  
  class << self
  
    def storage
      @storage ||= FakeStorage.new
    end
    
  end

end