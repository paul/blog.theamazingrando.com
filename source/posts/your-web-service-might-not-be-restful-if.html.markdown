---
category: HTTP
tags:
 - Hypermedia
---

#Your Web Service Might Not Be RESTful If...

The other day, I gave a brief talk about our HTTP Library, [Resourceful][]. After a few minutes of going over the features,
it became apparent to me that very few people have taken the time to appreciate the finer points of HTTP. Everyone who
calls themself a web application developer needs to take a few hours to read [RFC2616: Hypertext Transfer Protocol -- HTTP/1.1][rfc2616].
Its not very long, and increadibly readable for a spec. Print it out, and read a few sections when you go for your
morning "reading library" break. Unfortunately, a great many people got confused by it, and ended up reimplementing a lot
of http in another layer, and thats how we ended up with SOAP and XML-RPC. There's a good parable about
[how this all went of the rails for awhile][parable], until some people re-discovered a section in  Roy T. Fielding's
disseration, "[Representational State Transfer (REST)][rest]".

Needless to say, REST is making a huge comeback, at least in the agile startup communities. It's fast, lightweight, and
easy to put together. Ruby on Rails even has excellent support for getting up and running quicky. Sadly, though, it's
not quite right, and as a result, developers have misconstrued REST yet again, and its making things harder than they
really need to be, and also leading them down a path that leads to lots of headaches in the future. If you're interested
in learning more about REST, there's plenty of excellent resources on the [REST Wiki][rest-wiki], particularly
[REST In Plain English][plain-english].

For some of my examples, I'm going to pick on the [Pivotal Tracker "RESTful" API][tracker-api]. Sorry guys, I needed to
pick someone, and I love your product (I use it every day), but you're part of the reason for this post. I wanted to
write a client for your service, but its really much harder than it needs to be. The service violates many of the constraints
of REST, and therefore naming it "RESTful" is incorrect. You're not the only ones, though, so don't feel bad, nearly
EVERY API that claims to be RESTful isn't. For a look at one that gets it (mostly) right, check out [Netflix][].

# If Your Web Services Do Any of These Things, You're Doing it Wrong

1. Clients have to read documentation to know the locations of top-level resources.
2. Clients have to concatenate strings to get to the next resource.
3. You have an "API/Key/Token" in a header or a url.
4. You have a version string in a url.

## 1. Have a Minimum of Starting Points

If you look at the [Available Actions on Pivotal Tracker's API page][tracker-actions], you'll see they list several
actions that can be performed. This isn't REST, this is XML-RPC. Nearly everybody gets this one wrong. Due to the
amount of confusion, Roy Fielding [published a post][roy-hypertext] to stop people abusing the term "RESTful" and to try
and clarify what a real RESTful API is. His final point is:

> A REST API should be entered with no prior knowledge beyond the initial URI (bookmark) and set of standardized media
> types that are appropriate for the intended audience (i.e., expected to be understood by any client that might use
> the API).

The point here is that there should be only one resource that is the starting point for any interaction with the
service. This is called a "well-known" resource, and is never, *ever* allowed to change locations. If it does change,
you break every single client out there. By publishing a dozen or more well-known resources in their API docs, Tracker
is no longer permitted to change any of them. This increases the maintenance burden, because now they have to maintain
all these resources for the lifetime of the application, or deprecate any third-party clients.

If they had instead added a single resource that described the locations of these other resources, they would have much
more flexibility in the future. An example of the content of such a resource:

    <?xml version="1.0" encoding="UTF-8"?>
    <services>
      <service>
        <name>AllProjects</name>
        <href>http://www.pivotaltracker.com/services/projects</href>
      </service>
      <service>
        <name>AllActivities</name>
        <href>http://www.pivotaltracker.com/services/activites</href>
      </service>
    </services>

*Note: Yes, they list several other actions on their API. However, each of them violates another one of the REST
constraints, so I have ommitted them for the time being.*

Now every client just needs to know the name of the resource they're looking for, eg "AllActivites", and they can
continue as before. If, for some perfectly valid reason, Pivotal decides to change the name of "Activites" to, say,
"Actions", they only have to modify the `href` of the "AllActivities" service description, add a "AllActions"
service, and every single client using it by the name instead of a hardcoded href continues to work flawlessly, or
at least as well as it did before. Less maintenance burden on the service developers, and no burden at all for
the developer of a well-written client.

## 2. Don't Make a Client Construct URIs

In that very same bullet point, Roy continues...

> From that point on, all application state transitions must be driven by client selection of server-provided choices
> that are present in the received representations...

If you look at the [Tracker API docs Available API Actions][tracker-actions] for projects, you'll see "Single
project" and "All my projects". We already covered how to handle the "AllProjects" resource, an in the example above,
we remove the "Single project" resource entirely. So how do you get to the resource for a single project? Simple, you
follow its link in the "AllProjects" resource.

        <?xml version="1.0" encoding="UTF-8"?>
        <projects type="array">
          <project>
            <href>http://www.pivotaltracker.com/services/v2/projects/1</href>

            <id>1</id>
            <name>Sample Project</name>
            <iteration_length type="integer">2</iteration_length>
            <week_start_day>Monday</week_start_day>
            <point_scale>0,1,2,3</point_scale>

            <stories_href>http://www.pivotaltracker.com/services/v2/projects/1/stories?{-join|&|filter,limit,offset}</stories_href>
            <iterations_href>http://www.pivotaltracker.com/services/v2/projects/1/iterations</iterations_href>
            <activities_href>http://www.pivotaltracker.com/services/v2/projects/1/activities</activities_href>
          </project>
          <!-- ... -->
        </projects>

For a client to find a single project, they would know its name. They would GET the list of services, find "AllProjects"
by name, GET the "href" provided, and look for the project "Sample Project" by name. They could then use the href attribute
to obtain the single resource for the project. Additionally, we also have links to all the actions in the docs that required a
`PROJECT_ID` in the url. To get the iterations or activities for a project, a client has to only locate the project, and
follow the links.

You should also notice the part of the `stories_href` enclosed in `{braces}`. This is known as a [URI Template][uri-template],
and is very handy. If you noticed in pivotals API docs, they had three ways of getting stories: All stories, stories by
a filter, and stories by a limit and offset. I took the liberty of combining these into single href, using the template
to describe the query parameters. A ruby client, using the `Addressable::URI` library, could fill out that uri like this:

    template = Addressable::Template(stories_href)
    template.expand({
      "filter" => 'label:"needs feedback" type:bug'
    })

All these extra requests might seem like a rather long way of going about it, however, the advantages are immense:

Should Tracker become huge, and everybody and their grandmother starts using it to keep track of their development projects,
Tracker could outstrip the load of a single database. Since it appears they are using `AUTOINCREMENT id` columns for the
project id, sharding the `projects` table is going to be hard. However, if they were to start using `UUID` columns for
project ids, then sharding is a whole lot less complicated. However, if they change the project id in the API, everyone's
clients break. If clients were to instead follow the href, they can do whatever they want to the id, and existing
clients will have no trouble at all following.

But wait, it gets better. What happens if the service still isn't fast enough, for any number of perfectly plausible
reasons? Because they're using hrefs, they can put *anything they want* there. Say they decide to shard the application
servers, so every project with an odd-numbered id goes to `www1.pivotaltracker.com`, and everything even-numbered goes
to `www2.pivotaltracker.com`. They just have to update the links, and everyone's client continues working.

If all resources are specified like this, then a client can get to every resource from that one starting point. You are
free to move, rename, and add resources as you desire, without making things complicated for your API clients. Less
maintenance burden on you, and none on your users.

## Don't put an "API Token" in a custom header, or in the URIs

While there's nothing technically un-RESTful about this, its still annoying to your clients. And unless you have a
full-time security expert on your staff, you probably did it wrong, and its not nearly as secure as you think it is.
It's also vulnerable to man-in-the-middle attacks and replay attacks, unless you use SSL. And if you **do** use SSL,
then you've thrown away one of the major advantages of HTTP, which is caching. Just about every HTTP server and
proxy are able to handle caching, and if they operate to spec, they're not allowed to cache SSL documents. I'll get
more into caching in a future blog post, just realize that it can be immensely beneficial to the performance of your
application, and you're going to want to do everything you can to facilitate that.

Luckily, you have a third option: HTTP Digest Authentication. Its been vetted by security professionals and time, and
is almost certainly more secure than some secret key you've come up with. There are many varieties of Digest auth. The
one most useful for RESTful web services uses an algorithm of "MD5-sess" and Quality of Protextion (qop) of "auth". The
MD5-sess algorithm allows for 3rd-party authentication services, and not requiring the server to maintain a plaintext
copy of the users' passwords. A qop of "auth" protects against chosen-plaintext cryptanalysis attacks, by having a
counter incremented by the client, and a client-generated nonce. For a quick overview, Wikipedia has a [good article][digest-wiki],
and be sure to check out the spec, [RFC2617]. Here's a simple example to see whats going on. Client requests are
denoted by `>`, with server responses `<`. This obviously isn't the whole content, just the interesting bits.

    > GET /

    < HTTP/1.1 401 Authorization Required
    < WWW-Authenticate: Digest
                        qop="auth",
                        realm="My RESTful Application",
                        opaque="55dd3242dd79740cefb67528b983bc8e",
                        algorithm=MD5-sess,
                        nonce="MjAwOS0wNy0xOSAyMDozMToyOToxODQ2NjA6MjAxZjRiMjVjZjRiYTc0MDEwNWIwY2U2NWIxMGNjNj"

    > GET /
    > Authorization: Digest
                     username="admin",
                     qop="auth",
                     realm="My RESTful Application",
                     algorithm="MD5-sess",
                     opaque="55dd3242dd79740cefb67528b983bc8e",
                     nonce="MjAwOS0wNy0xOSAyMDozMToyOToxODQ2NjA6MjAxZjRiMjVjZjRiYTc0MDEwNWIwY2U2NWIxMGNjNj",
                     uri="/",
                     nc=00000001,
                     cnonce="Mjg5MDIz",
                     response="1b8e5cdcd8d49ca65e3d6142567e44cf"

    < HTTP/1.1 200 OK
    < Authentication-Info: qop=auth,
                           nc=00000001,
                           cnonce="Mjg5MDIz",
                           nextnonce=00000002


Digest auth works when the client make an initial request without any authentication info. The server responds with a
401, and provides a few parameters to the client in the `WWW-Authenticate` header. The `realm` is a string used to
identify the application.  The client uses MD5 to hash together their `username`, the `realm` and their `password`.
This is referred to as `HA1`. When the user was created, the server did the same, and `HA1` is what is stored in the
database.

The client then generates a random string (the "client nonce" or `cnonce`) and increments a counter ("nonce counter" `nc`).
It hashes method as an uppercase string ("GET") and the URI ("/") together to produce `HA2`. Finally, it hashes `HA1`,
`HA2`, the `nonce`, `nc`, `cnonce`, and `qop` all together to arrive at `response`. It packages this all up into the
`Authorization` header, and makes the request again. The server has all the information it needs (it stored the `HA1`
instead of the plaintext password) to hash the same parameters itself. If it arrives at the same `response`, then it
knows the client knows the password for the user, and allows it to proceed.

Optionally, the server can provide an `Authentication-Info` header attached to the response. This provides enough
information for the client to automatically authenticate for the next request, without having to get a 401 again.
An alternative would be to just keep using the same `nonce` over and over, but this may be subject to replay attacks.
The downside of this, though, is that the client cannot pipeline requests.

## Don't put the API version in the URI

Several web services (including Tracker's) have uris that look like `http://myapp.com/v1/projects` or
`http://myapp.com/projects?v=2`. While this is perfectly RESTful, it seems a bit odd. From a pedantically REST-view,
`/v1/projects/1234` and `/v2/projects/1234` are the locations of totally different resources, when, in fact, they are
simply different **representations** of the same resource. From a more practical standpoint, say a client is written
when only version one of a service is available, and it stores ("bookmarks") some of these resources. Some time later,
the application team decides they need to release some incompatible changes to their API, so they increment the version.
Some time after that, the client upgrades to support the new version. However, the upgrade is not as clean as it might
be, because they still have the saved locations pointing to the old version. The client either needs to support *both*
versions, or write a tool that does, so it can migrate the url to their new locations. They could munge the urls, but
if one of the incompatible changes was going from integer ids to UUIDs, they have no choice.

Luckily, HTTP has a built-in solution to this problem: Content Negotiation. It makes use of two headers, `Accept` on
the client side, and `Content-Type` on the server side. The Tracker services serve everything back with a `Content-Type`
of `application/xml`. Its not just any old XML, however, it is a specific form of XML, the schema of which is described
in their API docs. This is the situation for which the use of mimetypes is intended. If every form of image out there
just used a mime-type of `image`, we'd have a much harder time of things. Luckily, there's more than that, with `image/gif`,
`image/png`, and `image/jpeg`, which all represent different encodings of images. Following the same idea, Tracker could
instead use something like `application/vnd.pivotal.tracker.v1+xml`. Yes, its still XML, but its Pivotal Tracker Version
1 flavor of XML. Then when Pivotal decides its time for incompatible changes, they only have to add an additional content
type, `application/vnd.pivotal.tracker.v2+xml`.

Following this idea, now a project always lives at `/projects/1234`. This is better, because while `v1` and `v2` of a
project probably aren't different, their representations are. When a client updates versions, their links don't break,
nor do they have to support two or more versions.

I've only just brushed the surface of this topic. For more, [Peter Williams][peter] has an excellent discussion of it
[here][versioning1], [here][versioning2], and [here][versioning3]. (disclaimer &emdash; Peter is a former coworker and
personal friend. This section and his posts are about a solution we came up with for a project.)

# Now You Don't Have Any Excuses

I hope that this post serves as a good description of why you shouldn't be designing web services the way every body
else does. It seems that everyone is just copying everyone else, without really understanding the pros and cons of the
implementations. I hope this sparks some discussion, because I don't know that these are even the best way to be doing
it, I just know from the experience of writing both applications and consumers, they way everyone is doing it now is
much more difficult than it needs to be.


[Resourceful]:    http://github.com/paul/resourceful
[rfc2616]:        http://www.w3.org/Protocols/rfc2616/rfc2616.html
[rest]:           http://www.ics.uci.edu/~fielding/pubs/dissertation/rest_arch_style.htm
[parable]:        http://serialseb.blogspot.com/2009/06/fighting-for-rest-or-tale-of-ice-cream.html
[rest-wiki]:      http://rest.blueoxen.net/cgi-bin/wiki.pl?FrontPage
[plain-english]:  http://rest.blueoxen.net/cgi-bin/wiki.pl?RestInPlainEnglish
[tracker-api]:    http://www.pivotaltracker.com/help/api
[Netflix]:        http://developer.netflix.com/docs
[tracker-actions]: http://www.pivotaltracker.com/help/api#api_actions
[roy-hypertext]:  http://roy.gbiv.com/untangled/2008/rest-apis-must-be-hypertext-driven
[uri-template]:   http://bitworking.org/projects/URI-Templates/
[digest-wiki]:    http://en.wikipedia.org/wiki/Digest_access_authentication
[RFC2617]:        http://www.ietf.org/rfc/rfc2617.txt
[peter]:          http://barelyenough.org
[versioning1]:    http://barelyenough.org/blog/2008/05/versioning-rest-web-services/
[versioning2]:    http://barelyenough.org/blog/2008/05/versioning-rest-web-services-tricks-and-tips/
[versioning3]:    http://barelyenough.org/blog/2008/05/resthttp-service-versioning-reponse-to-jean-jacques-dubray/
