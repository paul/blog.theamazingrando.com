---
category: Tips & Tricks
tags:
  - Ruby
  - DryRb
---

# Using Dry::Container for Dependency Injection

The point of this post isn't to convince you of the usefulness of [Dependency
Injection][di] there's been plenty of [pixels spilled about it already][di2].
Instead, I want to talk about using [Dry::Container][dry-container] to
alleviate some of the pain points that DI introduces.

[di]: https://dry-rb.org/gems/dry-container/0.8/#introduction
[di2]: https://visualstudiomagazine.com/articles/2014/05/01/how-to-refactor-for-dependency-injection.aspx
[dry-container]: https://dry-rb.org/gems/dry-container/0.8/

The first problem is when one object calls another, and both are using DI. For
example, say you have a Command object that calls and Adapter object that
finally calls the Client object. You end up with long chains of DI objects
being injected into objects at a higher level, and it quickly becomes unwieldy,
particularly for testing. Imagine we have something like this:

```ruby
class MyCommand
  attr_reader :adapter

  def initialize(adapter: MyAdapter.new)
    @adapter = adapter
  end

  def call(args)
    # do stuff
    adapter.do_something(params)
  end
end

class MyAdapter
  attr_reader :client

  def initialize(client: MyClient.new)
    @client = client
  end

  def do_something(params)
    # do stuff
    client.make_request(url, json)
  end
end

class MyClient
  attr_reader :http

  def initialize(http: HttpClient.new(timeout: 5))
    @http = http
  end

  def make_request(url, json)
    http.auth(user, pass).post(url, json: json)
  end
end
```

In an integration test, you want to set up a mock client for the Client object
to use, so it doesn't make any real requests.  A typical solution is involves
complicated test setup:

```ruby
# my_command_spec.rb

RSpec.describe MyCommand do
  let(:http)    { instance_spy(HttpClient) }

  let(:client)  { MyClient.new(http: http) }
  let(:adapter) { MyAdapter.new(client: client) }
  let(:command) { described_class.new(adapter: adapter) }

  it "should make an http call" do
    command.call(:send_message)
    expect(http).to have_received(:post).with("http://myapp.example/send_message",
                                              json: { "text": "Hello!" })
  end
end
```

In our integration test for `MyCommand`, we have to set up a whole lot of other
intermediate objects, just so we can inject the spy in at the lowest level. It
seems strange that the test for this high-level business object needs to care
about the low-level details about how the client is calling our HttpClient.
Additionally, we probably have different things using the Adapter or MyCommand
themselves, and the tests for those will need the same setup. Then, if we do
any refactorings around how the Command -> Adapter -> Client pattern is set up,
we'll have to come fix the setup for all these tests, which becomes tedious and
error-prone.

Another alternative would be to set up all the intermediate objects to allow
`http` to be injected, and pass it all the way through to the thing that cares
about it.

```ruby
class MyCommand
  attr_reader :adapter

  def initialize(adapter: MyAdapter, client: MyClient, http: HttpClient.new(timeout: 5))
    @adapter = adapter.new(client: client, http: http)
  end
end

class MyAdapter
  attr_reader :client

  def initialize(client: MyClient, http: HttpClient.new(timeout: 5))
    @client = client.new(http: http)
  end
end

class MyClient
  attr_reader :http

  def initialize(http: HttpClient.new(timeout: 5))
    @http = http
  end
end
```

This isn't great either, because now all the outer objects have to
pass through a thing they don't care about at all. Its also easy to loose track
of them, which object needs which dependency. Also, if `MyCommand`'s job is to
decide which of 5 Adapters it needs to send the message, it has to have 5
different clients injected.

The other issue I have with Dependency Injection is that once you start using
it, it makes sense to use it for *everything*. The problem with that, however,
is that you quickly run into very long and noisy `#initialize` methods:

```ruby
class MyCommand
  attr_reader :http, :logger, :instrumenter, :error_handler

  def initialize(http: HttpClient.new(timeout: 5),
                logger: Rails.logger,
                instrumenter: ActiveSupport::Notifications,
                error_handler: Honeybadger)
    @http = http
    @logger, @instrumenter, @error_handler = logger, instrumenter, error_handler
  end
end
```

I found that nearly every object I had was injecting that triplet of `[:logger,
:instrumenter, :error_handler]`, which got fairly tedious. While this maybe
could be resolved with a small object like what's used for [Primitive
Obsession](https://refactoring.guru/smells/primitive-obsession), I don't have a
good name for that object.

These two problems are particularly exacerbated when you need to pass through a
mock logger or instrumenter, and test the calls made to that. Now you need to
inject a whole lot of unrelated things, some of which the object doesn't care
about, and it gets messy quickly.

## Dry::Container

First, lets take a look at what a Dry::Container looks like:

```ruby
module MyApp
  module Container
    extend Dry::Container::Mixin

    register(:error_handler) { Honeybadger }
    register(:instrumenter)  { ActiveSupport::Notifications }
    register(:logger)        { Rails.logger }

    namespace(:clients) do
      register(:http)   { HttpClient.new(timeout: 5) }
      register(:github) { Octokit::Client.new(login: config.github_user, password: config.github_password) }
      register(:heroku) { PlatformAPI.new(token: config.heroku_token) }
    end
  end
end
```

To use the values within a Container, its fairly simple, you can treat the
container like a Hash:

```
http = MyApp::Container["clients.http"]
http.get("https://myapp.example/")
```

We can inject them into our objects be referencing them through the container,
rather than directly:

```ruby
class MyClient
  attr_reader :http

  def initialize(http: MyApp::Container["clients.http"])
    @http = http
  end

  def make_request(url, json)
    http.auth(user, pass).post(url, json: json)
  end
end
```

This, when coupled with [dry-container's stub
feature](https://dry-rb.org/gems/dry-container/0.8/testing/#stub), lets us
avoid complex test setup or deep injection:

```ruby
# in spec_helper.rb or something:
require 'dry/container/stub'
MyApp::Container.enable_stubs!

# In your test:
RSpec.describe MyCommand do
  let(:http) { instance_spy(HttpClient) }

  around do |example|
    MyApp::Container.stub("clients.http") { http }
    example.run
    MyApp::Container.unstub("clients.http")
  end

  it "should make an http call" do
    command.call(:send_message)
    expect(http).to have_received(:post).with("http://myapp.example/send_message",
                                              json: { "text": "Hello!" })
  end
end
```

_Aside_: In our app, we have that wrapped in a helper:
`stub_container(MyContainer, http: fake_client) { ... }`. Inside the block its
stubbed, then un-stubbed when the block ends.

### Auto-inject

A separate gem, [Dry::AutoInject](https://dry-rb.org/gems/dry-auto_inject/0.6/)
can work with our containers to help eliminate the boilerplate when injecting
many dependencies into a class. You can set it up in your container:

```ruby
module MyApp
  Import = Dry::AutoInject(Container)
end
```

Then, in your objects:

```ruby
class MyCommand
  include MyApp::Import[:logger, :instrumenter, :error_handler]
  include MyApp::Import["clients.http"]

  def call(args)
    instrumenter.instrument("MyCommand.call") do
      logger.info("doing stuff")
      http.post("https://myapp.example/")
    end
  end
end
```

It looks a bit strange, but essentially `include MyApp::Import[:foo]` is a macro that generates code like:

```ruby
attr_reader :foo

def initialize(foo: MyApp::Container[:foo])
  @foo = foo
end
```

When you have a lot of dependencies to inject, it really cuts down on the
boilerplate. One thing to make a note of, however, if you have non-DI args
passed to your `#initialize` method, you have to remember to call `super`.

```ruby
class MyCommand
  include MyApp::Import[:logger, :instrumenter, :error_handler]

  def initialize(user:, **deps)
    @user = user
    super(**deps)
  end
end
```

Hopefully you find this helpful, we certainly have. Dependency Injection is a
powerful tool that makes organizing and testing code a much cleaner experience,
and dry-container and dry-auto_inject are a nice bit of polish over some of the
tedious or boilerplate parts that come with it.

