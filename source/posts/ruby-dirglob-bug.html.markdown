---
category: Tips & Tricks
tags:
 - Ruby
---

#Ruby Dir.glob bug

To further elaborate on Yehuda's [twit](http://twitter.com/wycats/status/1124457823):

    [~/tmp][rando@apollo]
     % mkdir first first/second
    [~/tmp][rando@apollo]
     % touch first/second/test.txt
    [~/tmp][rando@apollo]
     % chmod -x first
    [~/tmp][rando@apollo]
     % ls first/second/*.txt
    ls: cannot access first/second/*.txt: Permission denied
    [~/tmp][rando@apollo]
     % irb
    irb(main):001:0> Dir.glob('first/second/*.txt')
    => []

If you try to glob some things in a directory that has some ancestor missing the eXecute permission, ruby doesn't give any indication of an error.

This took Yehuda and I about 30 minutes to track down why a merb app wasn't loading bundled gems under passenger. Apache was running as nobody, and the parent dir of the app was missing the global execute permission.

