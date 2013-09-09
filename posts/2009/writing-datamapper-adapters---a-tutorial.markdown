#Writing DataMapper Adapters - A Tutorial

Introduction
------------

The adapter API for DataMapper has been in a bit of flux recently. When I submitted
my proposal for a [talk at MountainWest][mwrc-talk], adapters were irritatingly complex to write.
You just needed to know too much about DataMapper's internals to be able to write one.
A week before the conference began, I started a significant effort to re-write the API to make
it easier. I succeeded, a little too well; my 30 minute talk only took 15. Since then,
I've written a couple more adapters from scratch, and refined the API further. This post
will serve as notes on the changes that I've made, and a tutorial on writing adapters.

The API changes are currently only in my branch, but they will be merged into the
[DataMapper/next][github-dm-next] branch. For now, you'll need to use my 
[adapters_1.0][github-adapters1.0] branch.

This tutorial will follow my process as I make a DataMapper adapter for [TokyoTyrant][tokyotyrant]. You
can grab the code from my github repo, [paul/dm-tokyotyrant-adapter][tt-adapter].

Setup
-----

I'll assume you know how to build a gem, and get it all set up using your favorite gem builder, 
so I'm going to skip all that. To begin, we only need a couple files. First (of course!), the spec:

### spec/dm-tokyotyrant-adapter_spec.rb

    require File.dirname(__FILE__) + '/spec_helper'
    
    require 'dm-core/spec/adapter_shared_spec'
    
    describe DataMapper::Adapters::TokyoTyrantAdapter do
      before :all do
        @adapter = DataMapper.setup(:default, :adapter   => 'tokyo_tyrant',
                                              :hostname  => 'localhost',
                                              :port      => 1978)
      end
    
      it_should_behave_like 'An Adapter'
    
    end

And thats all there is to it. We make an `@adapter` instance var, which gets returned from
`DataMapper.setup`, and then run the adapter shared spec. As of now, the shared spec is fairly
thorough, but its far from comprehensive. If we run this now, we'll get some errors about not finding
the `TokyoTyrantAdapter`. So, lets go make it.

Initialization
--------------

### lib/dm-tokyotyrant-adapter.rb

    require 'dm-core'
    require 'dm-core/adapters/abstract_adapter'       # 1
    
    require 'tokyotyrant'
    
    module DataMapper::Adapters
    
      class TokyoTyrantAdapter < AbstractAdapter      # 2
        include TokyoTyrant

        def initialize(name, options)
          super                                       # 3

          @options[:hostname] ||= 'localhost'         # 4
          @options[:port]     ||= 1978

          @db = RDB::new                              
        end
      end

    end

Some of this is pretty TokyoTyrant-specific. Since the Ruby API isn't very Rubyish, I'm going
to skip over a lot of it, and just talk about the DataMapper/adapter specific stuff. Referencing 
the comments in the code above:

1. `require` the abstract adapter explicitly, since its not `require`'d as part of requiring dm-core.
2. Make a class that follows the naming convention `#{AdapterName}Adapter` so that DataMapper can find it 
   when we use the `:adapter => 'adapter_name'` option. Inherit from AbstractAdapter as well, as it will 
   provide us with many helpers we'll be using.
3. Make an `initialize` method, and call super. This will turn any provided options into a Mash (a Hash
   that can use a string and a symbol as the same key. It handles a little other setup for you, as well.
4. The rest is Tyrant-specific, but useful to know. We set some default connection options, and initialze 
   a `@db` object.

If we run the spec now, it connects, and we get a bunch of pending specs, saying we need to implment `#read`, 
`#create`, etc...

    dm-tokyotyrant-adapter/master % rake spec
    (in /home/rando/dev/dm-tokyotyrant-adapter)
    *****
    
    Pending:
    
    DataMapper::Adapters::TokyoTyrantAdapter needs to support #create (Not Yet Implemented)
    /usr/lib/ruby/gems/1.8/gems/dm-core-0.10.0/lib/dm-core/spec/adapter_shared_spec.rb:52
    
    DataMapper::Adapters::TokyoTyrantAdapter needs to support #read (Not Yet Implemented)
    /usr/lib/ruby/gems/1.8/gems/dm-core-0.10.0/lib/dm-core/spec/adapter_shared_spec.rb:75
    
    DataMapper::Adapters::TokyoTyrantAdapter needs to support #update (Not Yet Implemented)
    /usr/lib/ruby/gems/1.8/gems/dm-core-0.10.0/lib/dm-core/spec/adapter_shared_spec.rb:107
    
    DataMapper::Adapters::TokyoTyrantAdapter needs to support #delete (Not Yet Implemented)
    /usr/lib/ruby/gems/1.8/gems/dm-core-0.10.0/lib/dm-core/spec/adapter_shared_spec.rb:129
    
    DataMapper::Adapters::TokyoTyrantAdapter needs to support #read and #create to test query matching (Not Yet Implemented)
    /usr/lib/ruby/gems/1.8/gems/dm-core-0.10.0/lib/dm-core/spec/adapter_shared_spec.rb:289
    
    Finished in 0.005982 seconds
    
    5 examples, 0 failures, 5 pending

Create
--------

    def create(resources)                                     # 1
      db do |db|                                              # 2
        resources.each do |resource|                          # 3
          initialize_identity_field(resource, rand(2**32))    # 4
          save(db, key(resource), serialize(resource))        # 5
        end
      end
    end

1. `resources` is an Array of DataMapper Resource objects.
2. `#db` is a helper to make TokyoTyrant's api a little more friendly. It handles connecting to the 
   ttserver, and yields the connection to the block. When finished, it closes the connetion.
3. Some adapters might be able to support bulk creates, like SQL INSERT. This one doesn't, so we'll loop 
   over every resource.
4. We'll need to set the identity field. More on this later.
5. Put the resource into the database. `#key` and `#serialize` are helpers, I'll explain them in a bit.

Something useful to note here: The resources being passed in to this method are the actual resources in use by DataMapper. That 
means that any modifications you make to them will also be automatically availble to anything using DataMapper. This is extremely 
useful for any data store that can provide a representation of the created object. If the data store set some fields as a result
of creation, eg, a `created_at` timestamp, or an `href` linking to the location of the resource, you can update the resource right
here, and not have to have DataMapper perform a `#read` to update the resource object.

If you're coming from an RDBMS world, you'll be familiar with sequences. Since you're here, learning how to write
adapters, I'm going to assume you're not going to be talking to a relational database. If thats the case, and you don't need
to support these kinds of sequences, you should probably use UUIDs or something similar for your identity fields. Sequences are
not scalable or distributable, they're a relic of the big RDBMSs. I only have this `#initialize_identity_field` line in there to
show how its done. As you can see, I'm not even picking it sequentially, but choosing a random number, instead, because I don't have
a resonable way to keep track of sequences. The method won't try to overwrite a value if one is already set, so take the opportunity to
use a UUID instead, and save everyone involved a bunch of trouble.%lt;/soapbox>

Because TokyoCabinet & Tyrant are key-value stores, I've written a couple helpers to try and coerce resources into a single key and 
value. First, I choose a key from the model name, and keys in the model, like so:

    def key(resource)
      model = resource.model
      key = resource.key.join('/')
      "#{model}/#{key}"
    end

We get the model, and the keys from the resource. One thing to keep in mind, is that DataMapper assumes composite keys for every model,
so even if a model has only a single key, `Resource#keys` will always return an array. We use that to build a string, like 
`Article/1234`. I chose a slash as the delimiter, because TokyoTyrant has a ReSTful interface, and it will make for pretty urls.

We also need to serialze the resource. I chose to serialize it as JSON, because its cross-platform, and lightweight. YAML or even XML would
also be ok choices, depending on what you may be interoperating with.

    def serialize(resource)
      resource.attributes(:field).to_json
    end

`resource#attributes` normally returns a Hash of `{:property_name => value}` pairs. DataMapper properties also can take an option, `:field`, 
which is used to indicate the name of the field used by the data store. Because we're writing an adapter to a data-store, thats what we want.
`#attributes` can take an optional argument to indicate what we want to use as keys. Here, I used `:field`, meaning I want the field attribute 
of the property. It will then return a Hash of the form `{"field_name" => value}` There usually won't be a difference, but its important
that adapters use the field instead of the name, so that someone writing a model can use the `:field` option to property correctly.

Let's run the spec again, and see how we did:

    dm-tokyotyrant-adapter/master % rake spec
    (in /home/rando/dev/dm-tokyotyrant-adapter)
    /usr/lib/ruby/gems/1.8/gems/rake-0.8.3/lib/rake/gempackagetask.rb:13:Warning: Gem::manage_gems is deprecated and will be removed on or after March 2009.
    ****..

    Finished in 0.009957 seconds

    6 examples, 0 failures, 4 pending

Read
----

    def read(query)
      model = query.model

      db do |db|
        keys = db.fwmkeys(model.to_s)
        records = []
        keys.each do |key|
          value = db.get(key)
          records << deserialize(value) if value
        end
        filter_records(records, query)
      end
    end

`#read` takes a DataMapper::Query object, which has everything needed to filter, sort, and limit records. For simple adapters, that don't have 
a native query language, you don't need to care. The `#filter_records` helper in AbstractAdapter will take care of everything for you. All you
need to do it provide it an Array of Hashes, using the `field` name of the property as the key. Since we use json to serialize the value, here 
we deserialize it back into a hash. We used field names as the keys, so no further translation is needed. TokyoTyrant provides the `#fwmkeys` 
method as a way to search for a key prefix, so we pass the model name in, because the model name is the first part of the key we used. We pass 
all the records we found in to `#filter_records`, which performs the filtering, and we then return the result.

Update 
------

    def update(attributes, collection)                                 # 1
      attributes = attributes_as_fields(attributes)                    # 2
      db do |db|
        collection.each do |resource|                                  # 3
          attributes = resource.attributes(:field).merge(attributes)   # 4
          save(db, key(resource), serialize(resource))                 # 5
        end
      end
    end

1. We take an `attributes` hash and a DataMapper::Collection. The `attributes` are in the form of `{Property => value}`, using the actual
   property object. A `Collection` is a set of resources. 
2. We need to convert the keys in the `attributes` has from `Property` objects into `:field` name. Luckily, AbstractAdapter provides
   `#attributes_as_fields`, which does exactly that.
3. Iterate over every resource in the collection
4. Update the attributes hash with the combination of the existing attributes, merged with the attributes we wish to update.
5. Write the whole thing back to the database.

You may also want to take a look at how the [InMemoryAdapter in dm-core][inmem-adapter] accomplishes the same task. It extracts the query 
used to build the collection, and looks for those records in its data store, using `#filter_records`. It then updates each record in-place.
Either way works fine, and the ease of which may depend upon the adapter. In TokyoTyrant, finding the records is harder than retrieving them,
so I opted to just re-save the ones I already had in the collection. An SQL adapter is able to update the records without loading them, so 
using the query is faster. ( "UPDATE {attributes} WHERE {query}" ).

Delete
------

    def delete(collection)
      db do |db|
        collection.each do |resource|
          db.delete(key(resource))
        end
      end
    end

At this point, it should all be self-explainatory. Just iterate over every resource in the colleciton, and delete its key from the db. Yay.

Conclusion
----------

And thats all there is to it. 3 hours, 2 beers, and ~100 LOC later, and we have a fully-capable adapter that can be used with DataMapper. I was
running the specs at every stage, but left them out for brevity. Here's the final run:

    dm-tokyotyrant-adapter/master % rake spec
    (in /home/rando/dev/dm-tokyotyrant-adapter)
    ......................................
    
    Finished in 0.175668 seconds
    
    38 examples, 0 failures

As I said before, the specs aren't exactly comprehensive, but they will be added to over the next few weeks. For now, they're good enough that you
can be pretty confident your adapter will work for most things.

Thanks for tuning in, leave a comment, or come visit me in #datamapper on freenode if you have any adapter questions.


[mwrc-talk]:            http://mwrc2009.confreaks.com/14-mar-2009-16-10-writing-adapters-for-datamapper-paul-sadauskas.html
[tokyotyrant]:   http://tokyocabinet.sourceforge.net/index.html
[github-dm-next]:       http://www.github.com/datamapper/dm-core/tree/next
[github-adapters1.0]:   http://www.github.com/paul/dm-core/tree/adapters_1.0
[tt-adapter]:           http://www.github.com/paul/dm-tokyotyrant-adapter
[inmem-adapter]:        http://github.com/paul/dm-core/blob/27a0277c8b00aa9d5be67a25a4113c437e4a6b34/lib/dm-core/adapters/in_memory_adapter.rb

