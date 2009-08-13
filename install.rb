require 'fileutils'

puts "Installing filtered_collections plugin"
puts

initializer_path_dest = Dir.getwd + "/config/initializers/"
initializer_path = Dir.getwd + "/vendor/plugins/filtered_collections/config/initializers/filtered_collections.rb"
unless File.exist?(initializer_path_dest + 'filtered_collections.rb')
  FileUtils.cp  initializer_path, initializer_path_dest
  puts "=> Copied initializer file."
else
  puts "=> Initializer already exists."
end

rel_collections_dir = "/lib/collections"
collections_dir = Dir.getwd + rel_collections_dir
unless File.exist?(collections_dir)
  FileUtils.mkdir collections_dir
  puts "=> Created directory for collections (#{rel_collections_dir})"
else
  puts "=> Directory (#{rel_collections_dir}) already exists"
end

rel_collections_test_dir = "/test/unit/collections"
collections_test_dir = Dir.getwd + rel_collections_test_dir
unless File.exist?(collections_test_dir)
  FileUtils.mkdir collections_test_dir
  puts "=> Created directory for collections tests (#{rel_collections_test_dir})"
else
  puts "=> Directory (#{rel_collections_test_dir}) already exists"
end