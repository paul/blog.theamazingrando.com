Title: Ruby rescues are not slow

I've heard several times that you should avoid exceptions because they are slow. They are in Java, so I think that has given them a bad name everywhere. The only real numbers I could find are from <a href="http://www.notsostupid.com/blog/2006/08/31/the-price-of-a-rescue/" title="http://www.notsostupid.com/blog/2006/08/31/the-price-of-a-rescue/">http://www.notsostupid.com/blog/2006/08/31/the-price-of-a-rescue/</a> . His 'plain' test is also missing the conditional that would also have to be executed (In this case, to make sure 5 is not 0). His post is also 18 months old, so I updated the 'plain' test and re-ran it (Upping the runs to 5,000,000). My plain test now looks like:
<pre lang="ruby">
x.report("plain") do
  for i in 1..n
    if 5.0 != 0.0
      1.0/5.0
    end
  end
end</pre>
And my results:
<pre>
% ruby --version
ruby 1.8.6 (2007-09-24 patchlevel 111) [x86_64-linux]
% ruby test_rescue.rb
user     system      total        real
plain    4.020000   0.010000   4.030000 (  4.034352)
safe     3.230000   0.010000   3.240000 (  3.238219)
rescue   3.270000   0.010000   3.280000 (  3.289843)</pre>
So it would seem, from my completely unscientific testing, that the rescue is actually <em>faster</em> than bounds-checking.