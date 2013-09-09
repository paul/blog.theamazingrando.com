#DataMapper Echo Adapter

I just wrote a simple adapter that can be used to investigate the DM Adapter API, and debug your own adapter. Its really simple to use:

    DataMapper.setup(:default, 
                     :adapter => :echo, 
                     :echo => {:adapter => :in_memory})


Set the `:echo` option to and options hash or connection uri that can initialize the adapter you want to wrap. This will print out the method calls, arguments, and return values to STDOUT.

    #read
    query: #<DataMapper::Query @repository=:default 
                               @model=Article 
                               @fields=[#<DataMapper::Property @model=Article @name=:id>, 
                                        #<DataMapper::Property @model=Article @name=:title>] 
                               @links=[] @conditions=[] @order=[] @limit=nil @offset=0 
                               @reload=false @unique=false>
     # => [#<Article @id=1 @title="Test" @text=<not loaded>>]

[Its on github](http://github.com/paul/dm-echo-adapter/tree/master)
[Example output](http://gist.github.com/77614)


