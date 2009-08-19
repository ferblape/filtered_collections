RAILS_ENV = 'test'

require 'test/unit'
require 'rubygems'
require 'active_record'
require 'mocha'
require 'ruby-debug'
require 'test/mocks/storage_mock'

class Element
  attr_accessor :id
  attr_accessor :name
  attr_accessor :value
  def initialize( value )
    self.id = Time.now.to_i + rand(1000)
    self.name = self.id.to_s(36)
    self.value = value
  end
end

class Owner
  attr_accessor :id
  attr_accessor :name
  def initialize
    self.id = Time.now.to_i + rand(1000)
    self.name = self.id.to_s(36)
  end
end

require 'lib/collection'

class CollectionTest < Test::Unit::TestCase
  
  def setup
    @owner = Owner.new
  end

  def test_initialize_collection
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :desc )
    assert_equal Element, c.elements_class
    assert_equal @owner.id, c.belongs_to
    assert_equal 0, c.locked
    assert_equal 0, c.total_elements
    assert_equal [], c.elements_ids
    assert_equal [], c.elements
  end
  
  def test_load_collection
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :desc )
 FilteredCollections.storage.expects(:get).with("filtered_collections/collection/Element_#{@owner.id}").returns(Marshal.dump(c).to_yaml)
    c = FilteredCollections::Collection.load( Element, @owner.id )
    assert_equal "filtered_collections/collection/Element_#{@owner.id}", c.key
  end
  
  def test_key_for_collection
    assert_equal "filtered_collections/collection/Element_#{@owner.id}", FilteredCollections::Collection.key_for( Element, @owner.id )
  end
  
  def test_key_for_collection_instance
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :desc )
    assert_equal c.key, FilteredCollections::Collection.key_for( Element, @owner.id )
  end
  
  def test_empty
    FilteredCollections::Collection.any_instance.stubs(:elements_ids).returns([1,2])
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :desc )
    assert !c.empty?
  end
      
  def test_include
    FilteredCollections::Collection.any_instance.stubs(:elements_ids).returns([1,2])
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :desc )
    assert c.include?(1)
    assert !c.include?(3)
  end
  
  def test_index
    FilteredCollections::Collection.any_instance.stubs(:elements_ids).returns([1,2])
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :desc )
    assert_equal 0, c.index(1)
    assert_nil c.index(3)
  end
  
  def test_store_elements
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :desc )
    assert_nil FilteredCollections.storage.get(c.key)
    e1 = Element.new(2)
    e2 = Element.new(1)
    c.store_elements( [e2, e1] )
    assert_equal 2, c.total_elements
    assert c.elements_ids.include?(e1.id)
    assert c.elements_ids.include?(e2.id)
    assert_not_nil FilteredCollections.storage.get(c.key)    
  end
  
  def test_store_element_when_no_elements
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :desc )
    assert_nil FilteredCollections.storage.get(c.key)
    e = Element.new(1)
    c.store_element( e )
    assert_equal 1, c.total_elements
    assert c.elements_ids.include?(e.id)
    assert_equal c.elements.first.keys.first, e.id
    assert_equal c.elements.first.values.first, e.value
    assert_not_nil FilteredCollections.storage.get(c.key)
  end

  def test_store_element_when_one_element_inserts_in_order_descending
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :desc )
    e1 = Element.new(2)
    e2 = Element.new(1)

    c.store_element( e1 )
    assert_equal 1, c.total_elements
    assert c.elements_ids.include?(e1.id)
  
    c.store_element( e2 )
    assert_equal 2, c.total_elements
    assert c.elements_ids.include?(e2.id)
    
    assert_equal c.elements.first.keys.first, e1.id
    assert_equal c.elements.first.values.first, e1.value
  end

  def test_store_element_when_one_element_inserts_in_order_ascending
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :asc )
    e1 = Element.new(2)
    e2 = Element.new(1)

    c.store_element( e1 )
    assert_equal 1, c.total_elements
    assert c.elements_ids.include?(e1.id)
  
    c.store_element( e2 )
    assert_equal 2, c.total_elements
    assert c.elements_ids.include?(e2.id)
    
    assert_equal c.elements.first.keys.first, e2.id
    assert_equal c.elements.first.values.first, e2.value
  end

  def test_store_existing_element_updates_it
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :asc )
    e1 = Element.new(2)
    e2 = Element.new(1)

    c.store_element( e1 )
    assert_equal 1, c.total_elements
    assert c.elements_ids.include?(e1.id)
  
    c.store_element( e2 )
    assert_equal 2, c.total_elements
    assert c.elements_ids.include?(e2.id)
    
    assert_equal [e2, e1].map(&:id), c.find(:all)
    
    e2.value = 5
    c.store_element( e2 )

    assert_equal 2, c.total_elements
    assert_equal [e1, e2].map(&:id), c.find(:all)
  end

  def test_find_all_elements_returns_inverse_order
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :desc )
    e1 = Element.new(1)
    e2 = Element.new(2)
    e3 = Element.new(3)
    c.store_element( e2 )
    c.store_element( e1 )
    c.store_element( e3 )
    
    result = c.find(:all)
    assert_equal 3, result.size
    assert_equal [e3, e2, e1].map(&:id), result
  end

  # We get sure the the order of storing is not important, but the value
  def test_find_all_elements_returns_inverse_order_and_correct
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :desc )
    e1 = Element.new(2)
    e2 = Element.new(1)
    e3 = Element.new(3)
    c.store_element( e2 )
    c.store_element( e1 )
    c.store_element( e3 )
    
    result = c.find(:all)
    assert_equal 3, result.size
    assert_equal [e3, e1, e2].map(&:id), result
  end
  
  def test_find_all_with_limit
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :desc )
    e1 = Element.new(1)
    e2 = Element.new(2)
    e3 = Element.new(3)
    c.store_element( e2 )
    c.store_element( e1 )
    c.store_element( e3 )
    
    result = c.find(:all, :limit => 2)
    assert_equal 2, result.size
    assert_equal [e3, e2].map(&:id), result
  end

  def test_find_all_with_limit_and_offset
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :desc )
    e1 = Element.new(1)
    e2 = Element.new(2)
    e3 = Element.new(3)
    e4 = Element.new(4)
    c.store_element( e2 )
    c.store_element( e1 )
    c.store_element( e3 )
    c.store_element( e4 )
        
    result = c.find(:all, :limit => 1, :offset => 2)
    assert_equal 1, result.size
    assert_equal [e2].map(&:id), result
  end

  def test_find_all_with_offset
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :desc )
    e1 = Element.new(1)
    e2 = Element.new(2)
    e3 = Element.new(3)
    e4 = Element.new(4)
    c.store_element( e2 )
    c.store_element( e1 )
    c.store_element( e3 )
    c.store_element( e4 )
        
    result = c.find(:all, :offset => 2)
    assert_equal 2, result.size
    assert_equal [e2, e1].map(&:id), result
  end
  
  def test_find_first
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :desc )
    e1 = Element.new(1)
    e2 = Element.new(2)
    e3 = Element.new(3)
    e4 = Element.new(4)
    c.store_element( e2 )
    c.store_element( e1 )
    c.store_element( e3 )
    c.store_element( e4 )
        
    result = c.find(:first)
    assert_equal e4.id, result
  end
  
  def test_find_first_with_offset
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :desc )
    e1 = Element.new(1)
    e2 = Element.new(2)
    e3 = Element.new(3)
    e4 = Element.new(4)
    c.store_element( e2 )
    c.store_element( e1 )
    c.store_element( e3 )
    c.store_element( e4 )
        
    result = c.find(:first, :offset => 2)
    assert_equal e2.id, result
  end
  
  def test_paginate
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :desc )
    e1 = Element.new(1)
    e2 = Element.new(2)
    e3 = Element.new(3)
    e4 = Element.new(4)
    c.store_element( e2 )
    c.store_element( e1 )
    c.store_element( e3 )
    c.store_element( e4 )
    
    result = c.paginate(:page => 2, :per_page => 2)
    assert_equal [e2, e1].map(&:id), result
  end
  
  def test_delete_element_removes_element_and_reorders
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :desc )
    e1 = Element.new(1)
    e2 = Element.new(2)
    e3 = Element.new(3)
    e4 = Element.new(4)
    c.store_element( e2 )
    c.store_element( e1 )
    c.store_element( e3 )
    c.store_element( e4 )
    
    assert_equal 4, c.total_elements
    c.delete_element( e3 )

    assert_equal 3, c.total_elements
    result = c.find(:all)
    assert_equal 3, result.size
    assert_equal [e4, e2, e1].map(&:id), result
  end
  
  def test_store_should_remove_duplicates_by_default
    c = FilteredCollections::Collection.new( Element, @owner.id, :value, :desc )
    e1 = Element.new(1)
    e2 = Element.new(2)
    e3 = Element.new(3)
    e4 = Element.new(4)
    c.store_element( e2 )
    c.store_element( e1 )
    c.store_element( e3 )
    c.store_element( e4 )
    c.store_element( e3 )
    c.store_element( e1 )
    
    assert_equal 4, c.total_elements
    assert_equal [e4, e3, e2, e1].map(&:id), c.find(:all)
  end

end
