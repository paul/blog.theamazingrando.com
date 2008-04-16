Title: I might as well get in on it, too

Modified for zshell:

<pre lang=bash>
paul@rando64 ~ % cat .zsh_history | awk -F \; '{print $2}' | awk '{a[$1]++}END{for(i in a){print a[i] " " i}}' | sort -rn | head
1435 cd
1057 git
1048 ls
950 vim
438 ruby
405 sudo
323 spec
272 emerge
265 rake
211 make

paul@rando64 ~ % wc -l .zsh_history
10027 .zsh_history

</pre>