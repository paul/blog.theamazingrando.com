#Resourceful 0.2.1

I'm pleased to introduce the next release of Resourceful, 0.2.1. This one has tons of bugfixes over 0.2, and is actually being used in production. There's only one real new feature to speak of is prettier logging output. It shows the runtime for requests, the resulting status code, and if it was retrieved from the cache. Some sample log output:

<pre>
    GET [http://core.ssbe.localhost/service_descriptors]
    -> Returned 200 in 0.0146s
    GET [http://core.ssbe.localhost/service_descriptors]
      Retrieved from cache
    -> Returned 200 in 0.0003s
</pre>

The code to do that is simple, as always:

<pre lang="ruby">
require 'rubygems'
require 'resourceful'

http = Resourceful::HttpAccessor.new(:logger => Resourceful::StdOutLogger.new,
                                     :cache_manager => Resourceful::InMemoryCacheManager.new)


res = http.resource("http://core.ssbe.localhost/service_desciptors")
mime_type = 'application/json'

res.get(:accept => mime_type)
res.get(:accept => mime_type)
</pre>

I've seen the release of a couple other Rest-HTTP libraries since I started working on Resourceful, [HTTParty][] and [rest-client][]. They're worth checking out, but they lack some of the more powerful features of Resourceful, such as the free HTTP Caching demonstrated above.

As always [bug reports][res-lh] and [patches][res-src] are appreciated.


[HTTParty]: http://railstips.org/2008/7/29/it-s-an-httparty-and-everyone-is-invited
[rest-client]: http://github.com/adamwiggins/rest-client/tree/master

[res-lh]: http://resourceful.lighthouseapp.com/projects/11479-resourceful/
[res-src]: http://github.com/paul/resourceful/tree/master
    
