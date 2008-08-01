Title: Resourceful - Adding default options

I just commited a change that allows you to specify some default headers to attach to all requests made on a resource. Best shown in an example, I'll use the sample code I gave in my [last post][]:

    require 'rubygems'
    require 'resourceful'
     
    http = Resourceful::HttpAccessor.new(:logger => Resourceful::StdOutLogger.new,
                                         :cache_manager => Resourceful::InMemoryCacheManager.new)
     
     
    res = http.resource("http://core.ssbe.localhost/service_desciptors", 
                        :accept => 'application/json')
     
    res.get
    res.get

Just a little less typing required.

[last post]: http://www.theamazingrando.com/blog/index.php/2008/07/31/resourceful-021/
