Title: About this Blog

After nearly a year on hiatus, I'm finally ready to start blogging again. I have several neat projects I've been working on over the last several months, and I need a place to write about them.

## Why I stopped using Wordpress

My [self-hosted Wordpress blog][oldblog] on my Slicehost served me well over the last few years. With a hodge podge of plugins and hacks, I was able to write my posts in markdown. I was still stuck writing them in the textarea of the browser, or copy-pasting them from my real editor to the browser, but it worked well enough. Eventually, though, I was updating Wordpress for security vulnerabilities more often than I was posting, and it was collecting a ton of spam comments. I decided that I didn't want to be in charge of that extra stuff any more.

I made several attempts to port my blog over to something else. I had a few simple goals:

 * The canonical place for my posts is git. Version control of the posts is definitely the way to go.
 * I just want to write content, not moderate spam, or manage plugins.
 * I don't want to maintain blogging software.

I looked for several solutions, but nothing really fit the bill. Posterous's announcement that they supported markdown got the wheels turning, though. Credit for the final bits go to [Peter Williams][] and [@spikex][], who got me started about how to manage drafts that I don't want published.

## Importing Wordpress

First, however, I had to get all my old posts out of Wordpress and into a git repo. I hacked together [this little script][import] which parsed the Wordpress XML dump. It goes over the posts and creates a branch for each, adds the markdown for the post, then merges the branch into master. I did this so that I could get a bit of metadata about the posts in the git repo. The first commit for a post would be the "created" date, and the commit when it was merged into master would be the "published" date.

Only after I did all this did I figure out that Posterous only exposed a "date", but this worked well together with another shortcoming: the lack of metadata on the post itself. I originally wanted a way to handle updating existing posts, but I had no metadata to find the post again. So for the post's "date", I used the most-recent commit date, at the time of the sync. As long as I keep the post "Title" unique, I'll be able to find the post again, and update the content, but not the date.

## Syncing with Posterous

So the official place for all my posts is my own git repo, where I can track changes, and manage it. I get to write using whatever editor I feel like, instead of a textarea in a browser, and I get to write them in markdown. I have a [script][sync] that I use to publish all my posts to Posterous. The script is rather dumb, and just updates everything that needs updated. I had planned on making it better, but due to some shortcomings in the Posterous API, and in the [postly][] ruby gem, I took the lazy way out. You can see in the script where I had to monkey-patch the postly gem to make it even work at all. Posterous also needs to read my last [blog post][]

I wanted to use Posterous's markdown, but it had its own shortcomings, like it couldn't handle the metadata, or definition lists, like the [maruku][] gem can. So just render it myself, and post the html body to Posterous. This means I'll eventually have to figure out things like syntax highlighting, but since Posterous supports inline gists, maybe I'll just do that.

## Finally

So, in conclusion, its not perfect, but it'll do. I'll probably write a follow-up post, about what the Posterous API needs to add, since their own docs say its incomplete, and they don't know what to do with it. It also exposed some flaws in the HTTParty gem, which I hadn't had exposure to until now. Its not really a bug, but rather a design decision, in that the request method only has two params: `post url, options = {}`. It tries to be smart about those options, and if you have one called `:body`, it becomes the body of the request. However, Posterous has a param in their API called `"body"`, which just confused everybody. Additionally, the postly gem crammed everything in the query parameters, which quickly runs into URL length limits for my admittedly verbose blog posts.

The world would be a better place if everyone would just use [Resourceful][]. `</shameless-plug>`

Overall, I wrote ~100 lines of Ruby to import my old wordpress blog, and sync the whole thing up to Posterous. I don't have to host or maintain anything, so its a definite win. I hope it gives my more time to write about all the cool shit I've been working on over the last few months, and well as my new project, [MongoMachine][]. Stay tuned!


[Peter Williams]:  http://barelyenough.org/
[@spikex]:         http://twitter.com/spikex
[oldblog]:         http://theamazingrando.com/blog
[import]:          http://github.com/paul/blog.theamazingrando.com/blob/master/lib/import.rb
[sync]:            http://github.com/paul/blog.theamazingrando.com/blob/master/lib/sync.rb
[postly]:          http://github.com/twoism/postly
[maruku]:          http://maruku.rubyforge.org/
[Resourceful]:     http://github.com/paul/resourceful
[MongoMachine]:    http://mongomachine.com
[blog post]:       http://blog.theamazingrando.com/your-web-service-might-not-be-restful-if

