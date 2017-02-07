---
category: Tips & Tricks
tags:
 - Rails
 - Logging
---

#Rails Logging to Syslog using Logging gem

When using a mongrel cluster, you can either log to a separate file for each mongrel instance, or you can log them all to the same file, but on a loaded cluster, there's a good chance your logged lines will get interleaved and be unreadable. Luckily, there's another way. The new replacement for log4r <a href="http://logging.rubyforge.org">Logging</a> can take care of this. It has a built-in way of <a href="http://www.ruby-forum.com/topic/142485">not interleaving the lines</a>, but (I think) its using lockfiles to do so, and if so, that's going to be detrimental to performance. The best solution has been around for 25 years, syslog. And with one of the more recent syslog daemons (syslog-ng, or rsyslog), you can set it up to log your mongrel log wherever you like.

First, install the logging gem: <code>sudo gem install logging</code>

Then, in config/environments/production.rb:

```ruby
require 'logging'
config.logger = returning Logging::Logger['mongrel'] do |l|
  l.add_appenders( Logging::Appenders::Syslog.new('my_rails_app') )
  l.level = :info
end
```

For more details, check out the <a href="http://logging.rubyforge.org">Logging</a> docs, but all I've done here is set the process name that it gets logged to as "my_rails_app", so change this to whatever your app name is.

Then, you can filter it in rsyslogd.conf:

```
:msg, startswith, " my_rails_app" /var/log/rails/production.log
```

And you're done!
