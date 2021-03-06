---
category: HTTP
tags:
 - Hypermedia
---

# In-Band vs. Out-of-Band: The Advantages of Hypermedia APIs

A good way to look at the advantages of a hypermedia-based API vs an "HTTP-RPC"
style one is to consider the differences between "In-Band" and "Out-of-Band"
information. A hypermedia API focuses on getting as much information in-band as
possible, reducing the burden on clients to deal with changes.

*Note: I originally considered this to help my team decide what path to take
when building V2 of our API, but decided it deserved a wider audience*

"In-Band" is anything that is transmitted within the primary transmission
channel. "Out-of-Band" refers to any communications that occur outside of that.

In the case of JSON APIs, I'll use "In-Band" to refer to the data in the JSON
payload itself, while "Out-of-Band" will refer to everything else you need to
know to consume that API, such as documentation or institutional knowledge.

Ideally, Out-of-Band knowledge should be minimized in an API, because it
requires more effort on the part of the client to consume the API. Any
Out-of-Band knowledge must be documented (or guessed!), and ends up being
hard-coded into the client implementations. This makes it very difficult, if
not completely impossible, to change in the future. One of the primary goals of
the API it to be resilient to change, otherwise we'd all be content with
scraping the HTML.  Similarly to how changes to your HTML content or layout
don't break the clients consuming it (browsers), so should clients of your API
be resilient to changes to your JSON. It is the Out-of-Band knowledge that
prevents this from happening.

A non-comprehensive list of things you have to know to consume any API, whether
that knowledge is In-Band or Out-of-Band might include:

 * The data itself.
 * The types of data in the payload.
 * How to fetch more data.
 * How to change some of the data on this resource.
 * How to create a new instance of this resource.
 * When creating or updating, which fields are optional.

## HTTP/RPC

Lets take a look at a typical JSON API:

```javascript
// GET /api/v1/posts/1
{
  "id": 1,
  "title": "In-Band vs Out-of-Band",
  "author_id": 1,
  "summary": "Hypermedia is great!",
  "tags": ["json", "api", "hypermedia"],
  "created_at": "2016-08-01T04:20:00Z"
}
```

The information that is In-Band vs Out-of-Band is pretty simple:

| In-Band         | Out-of-Band     |
| ---------       | -------------   |
| Fields & Values | Everything Else |

Unfortunately, this JSON API leaves a lot of questions unanswered, and the
developer consuming it will have to spend a lot of time consulting the
documentation. Some pretty typical questions you'll be asking, which require
Out-of-Band knowledge:

 1. How do I found out who the author is? I see that `author_id=1`, do I need
    to GET `/api/v1/authors/1`? Or `/users/1`?
 1. I see this post has tags. How do I get a list of all posts also tagged with
    one of these tags?
 1. This post has a numeric `id`. If I store this post locally in a database,
    should I set ID to an integer? Or will it sometimes be a mongo id? Or a
    UUID?
 1. If I want to amend or update some of these fields, do I need to return the
    full payload, or just the ones I want to change? Do I PUT it to this same
    URL, or POST it somewhere else, like `./revisions`?
 1. When creating a new post, do I POST it somewhere else? Which of these
    fields are required? Are there limits to the length of the title or
    summary?

Hopefully, this information is answered in the 100% complete and accurate
documentation, but sadly that not always the case. If we're needing to create a
client for this API ourselves, we're going to need to write a great deal of
code to capture that Out-of-Band knowledge in the client itself, to make our
client easier to use. If the creator of this API has provided us with a client,
the we'll still need to read that documentation to know which fields we can
expect from that client, and which to provide, and how to go about fetching the
author given its `id`.

In any case, this is far from ideal, but it is the status quo. Luckily, the
Hypermedia movement has gained enough traction that several major APIs are
using it, [such as GitHub][github-api].

## Hypermedia APIs

Which Out-of-Band knowledge is made In-Band by throwing some hypermedia into
the payload? Lets copy the example from a popular hypermedia API specification,
[JSON-API](jsonapi.org).

```javascript
// GET /api/v1/posts/1
{
  "type": "article",
  "id": "1",
  "attributes": {
    "title": "JSON API paints my bikeshed!"
  },
  "relationships": {
    "author": {
      "links": {
        "self": "http://example.com/articles/1/relationships/author",
        "related": "http://example.com/articles/1/author"
      },
      "data": { "type": "people", "id": "9" }
    },
    "comments": {
      "links": {
        "self": "http://example.com/articles/1/relationships/comments",
        "related": "http://example.com/articles/1/comments"
      },
      "data": [
      { "type": "comments", "id": "5" },
      { "type": "comments", "id": "12" }
      ]
    }
  },
  "links": {
    "self": "http://example.com/articles/1"
  }
}
```

| In-Band                         | Out-of-Band             |
| ---------                       | -------------           |
| Fields & Values                 | Required attributes     |
| Where to find author & comments | Types of attributes     |
| Where to update this post       | Method to use to update |

This is clearly an improvement of HTTP/RPC, there is quite a bit more knowledge
In-Band, and this is what basic Hypermedia provides us. However, it still
doesn't provide us with some basic knowledge about how to consume this API.
Most notably, it says nothing about the attributes themselves:

 1. What kind of data can we expect? Are they basic numbers or strings, or can
    we expect something encoded in them, like timestamps or embedded html tags?
 1. Can we always expect all these fields on a document of type "article"? Will
    some show up that aren't in this example, or does this example have any
    that other responses might not?
 1. If I want to create or update an "article", which fields must I provide,
    and which are optional?
 1. If I need to update this "article", I can guess that I use the "self" link
    provided, but should I `POST` or `PUT`? Does this endpoint support `PATCH`?

Its not just JSON-API, most JSON Hypermedia proposals (HAL, Collection+JSON) do
not provide a means to answer these questions In-Band, and as such, will have
to be documented Out-of-Band. Also, most of these Hypermedia standards are far
more verbose than the plain HTTP/RPC, which can dissuade developers from
considering the advantages.

While this is far superior to plan HTTP/RPC, we can still do better.

## JSON+LD

This usual reaction when someone brings up "RDF" and "Semantic Web" is to run
screaming before the horrors of a cryptic W3C spec is rolled out.
[JSON+LD][json-ld], however, is a breath of fresh air compared to the
convolution of the technologies it is based upon. Let's take a look at an
example of a JSON+LD document:

```javascript
// GET http://dbpedia.org/resource/John_Lennon
{
  "@context": "http://json-ld.org/contexts/person.jsonld",
  "@id": "http://dbpedia.org/resource/John_Lennon",
  "name": "John Lennon",
  "born": "1940-10-09",
  "spouse": "http://dbpedia.org/resource/Cynthia_Lennon"
}
```

Simple, right? Even a lay-web developer can understand this document. But how
does this move the Out-of-Band knowledge in JSON-API to In-Band JSON+LD? The
secret lies in that `@context` attribute. When we fetch that URL ("dereference"
in Semantic Web terminology) we get this:

```javascript
// GET http://json-ld.org/contexts/person.jsonld
{
  "@context": {
    "Person":          "http://xmlns.com/foaf/0.1/Person",
    "xsd":             "http://www.w3.org/2001/XMLSchema#",
    "name":            "http://xmlns.com/foaf/0.1/name",
    "nickname":        "http://xmlns.com/foaf/0.1/nick",
    "affiliation":     "http://schema.org/affiliation",
    "depiction":       { "@id": "http://xmlns.com/foaf/0.1/depiction", "@type": "@id" },
    "image":           { "@id": "http://xmlns.com/foaf/0.1/img", "@type": "@id" },
    "born":            { "@id": "http://schema.org/birthDate", "@type": "xsd:dateTime" },
    "died":            { "@id": "http://schema.org/deathDate", "@type": "xsd:dateTime" },
    "child":           { "@id": "http://schema.org/children", "@type": "@id" },
    "parent":          { "@id": "http://schema.org/parent", "@type": "@id" },
    "sibling":         { "@id": "http://schema.org/sibling", "@type": "@id" },
    "spouse":          { "@id": "http://schema.org/spouse", "@type": "@id" },
    "telephone":       "http://schema.org/telephone",
    // It goes on for awhile with more attributes, about 30 total
  }
}
```

Whew, that's a lot of stuff. However, from this, we can see clearly what all
the possible attributes we can expect to be returned from this endpoint.
Further, we know what types they are (`born` is a schema.org birthDate, and is
parsed as `xsd:dateTime`), and which can be links to something else (the ones
that have `"@type": "@id"`).

| In-Band                     | Out-of-Band             |
| ---------                   | -------------           |
| Fields & Values             | Required attributes     |
| Where to find the spouse    | Method to use to update |
| Where to update this person |                         |
| Possible attributes         |                         |
| Types of attributes         |                         |

We still don't know which attributes are required if we want to update the
resource, or what method to use, but we know a great deal more about the fields
and data types we can expect to be returned to us that we might need to handle.
The basic JSON-LD document is also much more readable for a human than the
JSON-API document, which is a big win in my book, and worth doing for that
characteristic alone. Furthermore, the JSON+LD document is also easier for
*computers* to read, through a process called expansion. This process follows a
simple algortihm to expand the source document based upon the context document
it links to, and there are libraries to do so in most common languages. Let's
run our document through the expansion process using the [tool on the
JSON+LD][json-ld-tool] site:

```javascript
[
  {
    "@id": "http://dbpedia.org/resource/John_Lennon",
    "http://schema.org/birthDate": [
      {
        "@type": "http://www.w3.org/2001/XMLSchema#dateTime",
        "@value": "1940-10-09"
      }
    ],
    "http://xmlns.com/foaf/0.1/name": [
      { "@value": "John Lennon" }
    ],
    "http://schema.org/spouse": [
      { "@id": "http://dbpedia.org/resource/Cynthia_Lennon" }
    ]
  }
]
```

It is much more verbose, but now a computer can pull out the attribute that
stores the person's "name", no matter what you decided to call it in your API
document, whether it is "Name" or "full_name" or "person_name" or whatever you
can come up with. As long as you add to the context a line like `"name":
"http://xmlns.com/foaf/0.1/name"`, then a computer can expand the document from
the context, and go look up the canonical "name" attribute. Similarly, it can
use the `@type` attribute on the birthDate field to know to parse that string
as an XMLSchema datatime to get a real date out of it.

But, there's still some knowledge that has to be provided Out-Of-Band, mainly
which attributes to we have to provide when creating a person, and which HTTP
methods to use to it. That's where Hydra comes in.

## Hydra

[Hydra][hydra] is a draft W3C spec that adds a vocabulary for transmitting
JSON-LD documents over a HTTP API. A Hydra api document looks exactly like the nice, simple JSON+LD example. The only change it makes is to add a `vocab` field to the context document:

```javascript
    "vocab": "http://www.markus-lanthaler.com/hydra/event-api/vocab",
```

Dereferencing this document gives us a very large document, describing all the
resources and endpoints provided by this API. (It doesn't have to be a single
large document, you can break it up per-resource if you have a very large API
surface.) Let's take a look at a subset of that document:

```
    {
      "@id": "http://xmlns.com/foaf/0.1/Person",
      "@type": "hydra:Class",
      "hydra:title": "Person",
      "hydra:description": null,
      "supportedOperation": [
        {
          "@id": "_:person_replace",
          "@type": "http://schema.org/UpdateAction",
          "method": "PUT",
          "label": "Replaces an existing Person entity",
          "description": null,
          "expects": "http://xmlns.com/foaf/0.1/Person",
          "returns": "http://xmlns.com/foaf/0.1/Person",
          "statusCodes": [
            {
              "code": 404,
              "description": "If the Person entity wasn't found."
            }
          ]
        },
        {
          "@id": "_:person_delete",
          "@type": "http://schema.org/DeleteAction",
          "method": "DELETE",
          "label": "Deletes a Person entity",
          "description": null,
          "expects": null,
          "returns": "http://www.w3.org/2002/07/owl#Nothing",
          "statusCodes": [ ]
        },
        {
          "@id": "_:person_retrieve",
          "@type": "hydra:Operation",
          "method": "GET",
          "label": "Retrieves a Person entity",
          "description": null,
          "expects": null,
          "returns": "http://xmlns.com/foaf/0.1/Person",
          "statusCodes": [ ]
        }
      ],
      "supportedProperty": [
        {
          "property": "http://schema.org/name",
          "hydra:title": "name",
          "hydra:description": "The person's name",
          "required": true,
          "readonly": false,
          "writeonly": false
        },
        {
          "property": "http://schema.org/birthDate",
          "hydra:title": "born",
          "hydra:description": "Date the person was born",
          "required": true,
          "readonly": false,
          "writeonly": false
        },
        {
          "property": "http://schema.org/spouse",
          "hydra:title": "spouse",
          "hydra:description": "Ther person's spouse, if any",
          "required": false,
          "readonly": false,
          "writeonly": false
        }
      ]
    }
```

This is a much larger document, but is pretty self-explanatory. Hydra is
providing the `supportedOperation` and `supportedProperty` fields, which answer
the last two Out-of-Band questions we had remaining.

`supportedOperation` lists all the HTTP verbs we can perform on this resource,
what they expect to be provided, what status codes they may return, and the
types of document it will give back. We can see that by performing a GET, we'll
get a Person object back. We can do a DELETE to remove the object, and we don't
have to provide anything, and don't expect anything back. We can do a PUT to
update the person, and its expecting a Person document, and will give us one
back, or a 404 if the person doesn't exist.

`supportedProperty` answers the question about which fields are required. We
can see that if we want to update this person, we'll need to provide a name and
their birthdate in the "born" field, but the spouse field is optional.

| In-Band                           | Out-of-Band   |
| ---------                         | ------------- |
| Fields & Values                   |               |
| Where to find the spouse          |               |
| Where & How to update this person |               |
| Possible attributes               |               |
| Types of attributes               |               |
| Which attributes are required     |               |
| What HTTP verbs are allowed       |               |


Finally, we have an API with very little Out-of-Band knowledge required to
consume it, or to write a client. In fact, if there's a Hydra client already
available for your preferred language, it will probably automatically work with
any Hydra API you can come up with, we won't have to waste time writing
specific libraries in every language for every random API out there.

Additionally, Hydra and JSON+LD can be added to nearly every existing HTTP/RPC
JSON API out there, simply by adding the `@context` field to link to the
context and Hydra vocab. It can even be done without modifying the document
itself, by adding an [HTTP Link header][hydra-link-header].

The Hydra spec is getting the finishing touches now, and there's a few
beginnings of client libraries out there already. It could definently use some
wider attention, but in the meantime, JSON+LD is already a standard used by
Google and Microsoft, and very well-supported. You can port or write your APIs
in the JSON+LD style now, and get 90% of the advantages, and start enabling
Hydra as it gets finalized. We could certainly use your help, come join us on the [Hydra mailing list][hydra-mailing-list] or in the [HTTP-APIs Slack channel][http-slack].




[github-api]:         https://developer.github.com/v3/
[json-ld]:            http://json-ld.org/
[json-ld-tool]:       http://json-ld.org/playground/
[hydra]:              http://www.markus-lanthaler.com/hydra/
[hydra-link-header]:  http://www.hydra-cg.com/spec/latest/core/#discovering-a-hydra-powered-web-api
[hydra-mailing-list]: https://lists.w3.org/Archives/Public/public-hydra/
[http-slack]:         http://slack.httpapis.com/



