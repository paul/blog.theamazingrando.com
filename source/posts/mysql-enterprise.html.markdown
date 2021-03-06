---
category: MySQL
tags:
 - Linux
 - MySQL
---

#MySQL Enterprise

I just came across this link <a href="http://jcole.us/blog/archives/2008/04/14/just-announced-mysql-to-launch-new-features-only-in-mysql-enterprise/">about some new MySQL features will be for Enterprise customers only</a>. The feature they mention here is online backups. I think I'm just going to stop using MySQL for any new projects.

I started using MySQL several years ago, near the end of the 3.x series. MySQL at that time was the easiest to get running, and at that point in my career, I wasn't too interested in SQL-compliance. I started playing around with postgres, but didn't use it for anything major. I found a lot of its concepts confusing, as my only real db experience was with MySQL (and Access, I'm ashamed to admit).

About 2 years ago I started working for my current employer. They used Postgres, so I bucked down and started learning it. I was impressed with what I saw, but still preferred MySQL. After I was there for a few months, we needed to develop a project that had 10,000s for INSERTs and DELETEs an hour. Testing showed that Postgres spent 50% of its time auto- or manual vacuuming. I switched the dbms over to MySQL using MyISAM tables (we didn't need transactions or anything fancy for this). It was a huge speed improvement, and we've been running both MySQL and Postgres to this day.

Its coming time to rewrite the project, to account for some changes to our design. I've been playing around, and the new auto vacuuming stuff in Postgres 8.3 is pretty good. I was going to do some further benchmarking to see if we should consider switching back to just Postgres, but after reading the post I linked above, I'm not going to even bother. Postgres is fast enough these days, its within a few percentage points of MySQL at most common things, and its much more standards compliant. Hopefully Sun will see the light, and realize that continuing down this path will destroy MySQL and the community. Free software developers (including myself) are a fickle bunch, and can jump ship or fork a project with startling speed.
