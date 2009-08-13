require 'rubygems'
require 'minitest/autorun'
require 'pathname'

module MiniTest
  class Mock
    def stub(method_name, return_value)
      self.class.__send__(:define_method, method_name) {  return_value }
      self      
    end
  end
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require File.dirname(__FILE__) + '/../filtered_collections'

include FilteredCollections

class MiniTest::Unit::TestCase
  def setup
  end
  
  def teardown
  end
end
