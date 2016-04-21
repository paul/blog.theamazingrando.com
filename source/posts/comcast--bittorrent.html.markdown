#Comcast & Bittorrent

Comcast user? Bummed that they're ruining your bittorrent? No problem. They way the kill your connection is by sending unsolicited TCP reset packets to your bittorrent client, making it think that the person you're downloading from has closed the connection. If you're using a good firewall/router, you can write a rule that will block it. I'm using <a href="http://www.polarcloud.com/tomato">Tomato</a> firmware for my Linksys WRT54G, and added the following line to my firewall scripts:
<code>
iptables -A {wan interface} -p tcp --dport {bittorrent port} --tcp-flags RST RST -j DROP
</code>
This drops all incoming RST packets to your bittorrent client. Now, this even removes the legitimate ones, if your source really does disconnect, you won't know about it. Luckily, the connection will timeout after about 10 minutes anyways, so its not that bad. I've been using this for a couple weeks now, and my bittorrent transfer speeds are back to what they were before Comcast started doing all this.