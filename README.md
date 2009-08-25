# Filtered Collections

_This plugin is a alpha version and has not been tested exhaustively in production_

http://github.com/ferblape/filtered_collections/tree/master

The main purpose of this plugin is to solve the problem of having collections of objects which cost a lot to calculate (for example, the last posts of my friends, but only one per each friend, or the last activity of the users from Spain). 

This is done by saving already filtered and calculated collections in a persistent storage (by the moment only Lightcloud with Tokyo Tyrant is supported) which is very fast to access.

Those collections are pluggables in your application, by defining them into the folder `lib/collections`: they are declared as new classes that have to inherit from `FilteredCollections::Collection` class.

By default a collection belongs to the objects of a class, i.e. an user. Every object that has a collection has a new method that refers to the collection.

## Requirements

This is not a generic plugin, but one with a lot of dependencies (opinions :D) and not easy to change:

  - Rails >= 2.0
  - Active Record >= 2.0
  - [Tokyo Tirant and Tokyo Cabinet](http://tokyocabinet.sourceforge.net/tyrantdoc/)
  - [lightcloud](http://github.com/mitchellh/lightcloud/tree/master) >= 0.8.0
  - [Will Paginate](http://github.com/mislav/will_paginate/tree/master)
  - `Memcached` is very recommendable
  - also is very recommendable a queue system such as `Starling` or `Delayed Jobs`
  
The idea is to let you to choose differente storages (you are welcome to fork it ;)

## Installation

    script/plugin install git://github.com/ferblape/filtered_collections.git
    
Also, you have to declare your lightcloud list of servers in `config/lightcloud.yml`.
    
## Basic usage
    
After installing it a new initializer will be copied into your `config/initializers` folder. That initalizer loads every file in `lib/collections` with extension `*.rb` and calls its method `self.set_callbacks` that we'll explain down.

As we said before, the idea is that the collections belong_to the objects of a class. For example, I want that a given user has a collection of the reviews created only by his friends. I can indicate this by adding:

    class User < ActiveRecord::Base
      ...
      has_collection :friends_reviews, :belongs_to => 'self.id'
      ...
    end

Automatically every user becomes the owner of one collection, and can access to it calling the method `:friends_reviews`. For example:

    >> User.first.friends_reviews.find(:all)
    => #<FriendsReviews:0x31f2e8c @belongs_to=1, @elements=[{21119=>Sun, 16 Aug 2009 10:26:10 UTC +00:00}], @elements_ids=[21119], @elements_class=Review(id: integer, user_id: integer, film_id: integer), @locked=0, @order=:desc, @total_elements=1, @order_by_attribute=:updated_at>
    
Of course, it is necessary to have declared a collection class with name `FriendsReviews` in `lib/collections` folder. What's the structure of a collection?

### Schema of a collection

    class FriendsReviews < FilteredCollections::Collection
  
      def self.attributes
        { :elements_class => Review, :order_by_attribute => :updated_at, :order => :desc }
      end
    
      def self.set_callbacks
        Review.send(:after_save, 
           Proc.new do |review|
            UserFriend.find(:all, :conditions => ["friend_id = ?", review.user_id], :select => "user_id").map(&:user_id).each do |user_id|
              eval("#{FriendsReviews.builder(:belongs_to => 'user_id')}.store_element( review )")
            end
            
           end
         )
      end
  
      def self.build_all
        User.find(:all, :select => "id").map(&:id).each { |user_id| self.build( user_id ) }
      end

      def self.build( user )
        user_id = user.is_a?(User) ? user.id : user
        UserFriend.find(:all, :conditions => ["user_id = ?", user_id], :select => "friend_id").map(&:friend).each do |friend|
          eval("#{self.builder(:belongs_to => 'user_id')}.store_elements( friend.reviews )")
        end
      end
  
    end
    
This is a real example of collection. Let's analyze it!

#### self.attributes

This class method declares a Hash with a list of required keys. This keys are:

  - `:elements_class`: the class of the elements stored in the collection. **There is one only type of objects in each collection**

  - `:order_by_attribute`: the attribute of the elements with wich they are goint to be ordered by. It can be a method or an attribute

  - `:order`: takes two values `:asc` or `:desc`
  
#### self.set_callbacks

This method defines a set of callbacks that are required to fill the collection.

In our example, every time an user saves a `Review`, for every one of his friends, their collections are updated with the new review.  

#### self.build_all

Build the collection for every object that owns one.

#### self.build

Build the collection for one object.


### Accessing the elements

The idea is that the way to access the elements of the collection is the same whatever the elements you store. You can get the elements of a collection in two ways:

  - `find(:type, options = {})` method, where `:type` can be `:all` or `:first` and the options only can be `:limit` and `:offset`. The order is given by the collection and cannot be changed, but you can always get all elements and reorder with Ruby sort methods.
  
  - `paginate( options = {} )` method, where the allowed options are `:page` and `:per_page`
  
Some examples:

    @reviews = current_user.friends_reviews.find(:all)
    @reviews = current_user.friends_reviews.paginate(:page => params[:page], :per_page => 50)
    

### Testing

As the collections for your application depend on you, also the tests. We recommend you to write some unit tests for every collection, specially for testing the callbacks.

For example, we have our tests in a folder named `test/unit/collections`.

It is important to notice that the callbacks of the collections (loaded in the initialized) are not set in the test environment, in order to not influence in the rest of tests (if you run your tests a lot of callbacks will be executed while they are not necessary all the time). So you'll have to call the method `set_callbacks` inside your test file.

## Acts as stored in cache

This is a small hack to improve the performance of the collections: internally, a collection stores the list of the identifieres of the elements. Methods `find` and `paginate` loads the object given its identifier with a simple `ActiveRecord::Base.find`.

We recommend you to use `acts_as_stored_in_cache` which stores every object in Memcached every time it changes. That way, when the collection is loaded, instead of a `ActiveRecord::Base.find` a read from Memcached is performed.

## Some advices

If you define a lot of callbacks your application will become slower and slower. Be careful and use a queue system.


## TODO

  - Improve the documentation with some examples

  - Define the exceptions
  
  - Let the storage system to be configurable

  - Allow to have elements of different classes
  
  - Allow transactions when big changes occurs

Copyright (c) 2009 [Fernando Blat](http://www.inwebwetrust.net), released under the MIT license