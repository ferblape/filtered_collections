require 'rubygems'
require 'will_paginate'

module FilteredCollections
  class Collection
    
    attr_accessor :elements_class
    attr_accessor :belongs_to
    attr_accessor :total_elements
    attr_accessor :locked
    attr_accessor :elements_ids
    attr_accessor :order_by_attribute
    attr_accessor :order
    attr_accessor :elements
    
    def initialize( elements_class, belongs_to, order_by_attribute, order )
      self.elements_class = elements_class
      self.belongs_to = belongs_to
      self.order_by_attribute = order_by_attribute.to_sym
      self.order = order.to_sym
      self.locked = 0
      self.total_elements = 0
      self.elements_ids = []
      self.elements = []
    end

    def self.load_or_initialize( elements_class, belongs_to, order_by_attribute, order )
      self.load( elements_class, belongs_to ) || self.new( elements_class, belongs_to, order_by_attribute, order )
    end

    def self.builder(options = {})
      attributes = self.attributes.merge(options)
      "#{self}.load_or_initialize( #{attributes[:elements_class]}, #{attributes[:belongs_to]}, :#{attributes[:order_by_attribute]}, :#{attributes[:order]} )"
    end
    
    
    # keys
    def self.key_for( elements_class, belongs_to )
      belongs_to = belongs_to.is_a?(Hash) ? belongs_to.map { |k,v| "#{k}_#{v}" }.sort.join('/') : belongs_to
      "#{self.to_s.underscore}/#{elements_class}_#{belongs_to}"
    end
    
    def key
      self.class.key_for(self.elements_class, self.belongs_to)
    end
    # /keys
    
    def empty?; self.elements_ids.empty? end
    
    def include?( element_id )
      self.elements_ids.include?( element_id )
    end
    
    def index( element_id )
      self.elements_ids.index(element_id)
    end
    
    def last_position; self.total_elements end
    
    def delete_element( element )
      element_id = element.is_a?(Fixnum) ? element : element.id
      if position = self.index( element_id )
        self.elements.delete_at(position)
      end
      self.total_elements -= 1
      self.reorder!
      self.save
    end
    
    def store_element( element, save = true )
      raise unless element.respond_to?(:id)
      raise unless element.respond_to?(self.order_by_attribute)
      
      sort_required = false
      if position = self.index( element.id )
        if self.elements[position].values.first != element.send(self.order_by_attribute)
          self.elements[position][element.id] = element.send(self.order_by_attribute)
          sort_required = true
        end
      else
        self.elements << {element.id => element.send(self.order_by_attribute)}
        self.total_elements += 1
        sort_required = true
      end
      if sort_required
        self.reorder!
      end
      self.save if save
    end

    def store_elements( elements )
      elements.each do |element|
        self.store_element( element, false )
      end
      self.save
    end
    
    # allowed values for options:
    #  - :limit 
    #  - :offset
    def find( search_type, options = {} )
      limit = nil
      if options[:limit]
        limit = options[:limit].to_i
        raise if limit <= 0
        limit = self.total_elements if limit > self.total_elements
      end
      offset = nil
      if options[:offset]
        offset = options[:offset].to_i
        raise if offset <= 0
        offset = self.total_elements if offset > self.total_elements
      end
      limit ||= self.total_elements
      offset ||= 0
      result = case search_type
      when :all
        if options.empty?
          self.elements_ids
        else
          self.elements_ids[offset...(offset+limit)]
        end
      when :first
        if options.empty?
          self.elements_ids.first
        else
          self.elements_ids[offset...(offset+1)].first
        end
      end
      if self.elements_class.respond_to?(:stored_in_cache)
        self.elements_class.load_collection(result)
      else
        return result
      end
    end

    # allowed values for options:
    #  - :per_page: default 50
    #  - :page: default 1
    def paginate( options = {} )
      page = options[:page].to_i || 1
      page = 1 if page <= 0
      page = self.total_elements if page > self.total_elements
      per_page = options[:per_page].to_i || 50
      per_page = 50 if per_page <= 0
      WillPaginate::Collection.create(page, per_page) do |pager|
        pager.total_entries = self.total_elements / per_page
        result = self.elements_ids[(page-1)*per_page...(page-1)*per_page + per_page]
        if self.elements_class.respond_to?(:stored_in_cache)
          result = self.elements_class.load_collection(result)
        end
        pager.replace(result)
      end
    end
    
    def self.load( elements_class, belongs_to )
      if obj = FilteredCollections.storage.get(self.key_for(elements_class, belongs_to))
        Marshal.load(YAML.load(obj))
      else
        nil
      end
    end
      
    def save
      FilteredCollections.storage.set(key, Marshal.dump(self).to_yaml)
    end
    
    def self.set_callbacks; end

    def self.build_all; end
    
    def self.build( id ); end
    
    def self.attributes; {} end

    protected
    
      def reorder!
        if self.order == :asc
          self.elements.sort!{ |a, b| a.values.first <=> b.values.first }
        elsif self.order == :desc
          self.elements.sort!{ |b, a| a.values.first <=> b.values.first }
        end
        self.elements_ids = self.elements.map{ |e| e.keys.first }
      end
      
      # TODO
      def locked?
        false
      end
      
      # TODO
      def transaction(&block)
        yield
      end
      
  end
end