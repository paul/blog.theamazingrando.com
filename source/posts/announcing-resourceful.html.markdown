---
category: Gems
tags:
 - Ruby
 - Resourceful
---

#Announcing Resourceful

<a href="http://resourceful.rubyforge.org/">Resourceful</a> is an advanced http library for Ruby that does all the fancy stuff that makes HTTP an amazing protocol. I'm pleased to announce the <a href="http://github.com/paul/resourceful/commits/rel_0.2">initial release</a> of Resourceful, 0.2. It already has some pretty cool features, with more to come.

This library is intended to make it easier for you to write your next whiz-bang Web2.0 app by performing the next level of HTTP features for you. There's some pretty nice stuff in the HTTP1.1 spec, but so far (at least in Ruby), everyone has has to roll their own. There has been some amazing stuff done on the server side of the HTTP spec in ruby, like mongrel, thin and rack, but the client side has been stuck with Net::HTTP for too long. We hope to remedy that.

Basic Example
-------------

Here's how you perform a very simple HTTP GET request:
<pre lang="ruby">
require 'resourceful'
http = Resourceful::HttpAccessor.new
resp = http.resource('http://rubyforge.org').get
puts resp.body
</pre>

Yeah, yeah, big deal, right? Every Yet-Another HTTP Library can do that. What makes Resourceful different is the additional features we added on.

Features that should make you want to use it
--------------------------------------------
I plan to write some full-length articles about these features in the future, to show how we're using them. For now, a brief description will have to suffice:

  * Redirection callbacks - GET requests automatically follow redirects, PUT, POST and DELETE do not. All allow callbacks to be set, that get called upon redirection. Should the callback return false, the redirection will not be followed. This will allow you to, for example, notify a local storage mechanism to update any links you might be storing with the new location.

  * Pluggable Authentication modules - Basic is built in, as is a very simple Digest one (but it's probably too simple to be really useful at this point. However, its very easy to roll your own, it only has to provide a couple of methods, and be registered with the @accessor.

  * Support for HTTP Caching - Most of the important parts of HTTP Caching, like storage, expiration, and validation are all handled for you. This is a simple in-memory store for the cached documents, but this is easily extensible. Some possible caching backends are a database, disk store, or memcached.

<strong>Update</strong>: My cohort on this also made a <a href="http://pezra.barelyenough.org/blog/2008/06/announcing-resourceful/">blog post</a> about Resourceful.
