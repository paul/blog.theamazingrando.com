---
category: HTTP
tags:
 - Hypermedia
---

#Dear Microsoft: Please Do Pinned Menus Like This Instead

With the IE9 betas beginning to come out, Microsoft have introduced an interesting new feature they're calling [pinned sites][]. For more details about how it works, you can check out the [Ars Technica preview][ars preview]. Essentially, you put several ms-vendor specific `meta` tags in the html of your header that describe the menu. The example given on the Ars preview uses this markup:

    <meta name="application-name" content="Ars Technica"/>
    <meta name="msapplication-starturl" content="http://arstechnica.com/"/>
    <meta name="msapplication-tooltip" content="Ars Technica: Serving the technologist for 1.2 decades"/>
    <meta name="msapplication-task" content="name=News;action-uri=http://arstechnica.com/;icon-uri=http://arstechnica.com/favicon.ico"/>
    <meta name="msapplication-task" content="name=Features;action-uri=http://arstechnica.com/features/;icon-uri=http://static.arstechnica.net/ie-jump-menu/jump-features.ico"/>
    <meta name="msapplication-task" content="name=OpenForum;action-uri=http://arstechnica.com/civis/;icon-uri=http://static.arstechnica.net/ie-jump-menu/jump-forum.ico"/>
    <meta name="msapplication-task" content="name=One Microsoft Way;action-uri=http://arstechnica.com/microsoft/;icon-uri=http://static.arstechnica.net/ie-jump-menu/jump-omw.ico"/>
    <meta name="msapplication-task" content="name=Subscribe;action-uri=http://arstechnica.com/subscriptions/;icon-uri=http://static.arstechnica.net/ie-jump-menu/jump-subscribe.ico"/>

...to produce this Windows 7 "pinned menu":

![Ars Technica pinned menu](http://static.arstechnica.com/ie-9-beta-1/ie9-ars-jump-list.png)

Kroc Camen at [Camen Design][camendesign] has a [pretty decent rant][rant] about how he thinks this is a bad idea. However, aside from the annoying proprietary `.ico` image format, the way Microsoft chose to use the `meta` element it isn't nearly as bad as what Mr. Camen proposes in its stead.

## The `Meta` Element

I take no issue with Microsoft's use of the `meta` element. It was always intended to be used by vendors for browser-specific features. From the [HTML5 working group wiki][whatwg wiki]:

> You may add your own values to this list, which makes them legal HTML5 metadata names. We ask that you try to avoid redundancy; if someone has already defined a name that does roughly what you want, please reuse it.

That said, this implementation is far from ideal. It is extremely verbose, 8 lines and over 1KB of text. Not surprising, as Microsoft and IE have always had issues with [extreme][ie accept] [verbosity][ms cdn]. This text will have to be sent with every page that a user might possibly want to "pin" your site from. Every page * every visitor * 1KB = a whole lot of bandwidth.

Camen's proposal is to use the new HTML5 `menu` element, in the body of the page. Not only does this have the same problems as above, its going to break accessibilty. Even if its it hidden from view by CSS, screen readers and other devices are going to be confused by having a `menu` stuck in the page, that is only tangentially related to the page's content.

Luckily, there is a perfectly acceptable solution: the `link` element.

## The `Link` Element

You're probably already familiar with [this element][link element]; you use it any time you want to attach a stylesheet to your page.

    <link rel="stylesheet" type="text/css" href="/style.css">

The `rel` attribute is a space-separated list of keywords that describe what *relationship* the linked content has to this page. So the IE pinned menu markup above could easily be replaced with:

    <link rel="ms-pinned-menu" type="application/xml" href="/pinned-menu.xml">

Then `pinned-menu.xml` could be simple xml (or HTML5 menu!) describing the menu. By doing it this way, web applications gain all the same benefits as serving linked stylesheets: it can be cached, and hosted as a static file on a CDN. Additionally, its much easier to extend the XML dialect as more browsers want to support Windows 7 pinned menus. Further, its a jumping-point to more integrated browser features, such as Android's "Menu" button, and single-page browser wrappers like Fluid and Prism.

I know its too late to get Microsoft to fix this in IE9, but hopefully the other browser vendors will be more forward-thinking, and let us developers do this the easy way, without adding kilobytes of additional markup to all our pages.



[pinned sites]:    http://msdn.microsoft.com/en-us/library/gg131029(VS.85).aspx
[ars preview]:     http://arstechnica.com/microsoft/news/2010/09/inside-internet-explorer-9-redmond-gets-back-in-the-game.ars/4
[camendesign]:     http://camendesign.com/
[rant]:            http://camendesign.com/blog/stop_this_madnessels
[whatwg wiki]:     http://wiki.whatwg.org/wiki/MetaExtensions
[ie accept]:       http://www.gethifi.com/blog/browser-rest-http-accept-headers
[ms cdn]:          http://stackoverflow.com/questions/2838635/ajax-microsoft-com-vs-cookieless-domain-for-cdn
[link element]:    http://dev.w3.org/html5/spec/Overview.html#the-link-element

