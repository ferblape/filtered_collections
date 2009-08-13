Dir.glob(RAILS_ROOT + '/lib/collections/*.rb').each do |collection|
  require collection
  # Sets callbacks in models
  collection_class = collection.split('/').last.split('.').first.camelize.constantize
  collection_class.send(:set_callbacks)
end
