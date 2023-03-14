# guardian

**guardian** is a buggy shellscript whose whole purpose is to interact with
the ipset and iptables facilities in order to quickly manage an IP ban list.

The behaviour is very simple: add an IP address into the list, run the
apply command and the banned IP set will be updated and the firewall will
be configured if needed.

The script makes sure that the firewall rule is set, and if it is not set it
will create the iptables rules again so that it proceeds to log and drop or
reject whenever one of the offending IPs tries to interact with the firewall.

## Dependencies

`ipset`, `iprange` and `iptables`. I could probably get away without iprange
since all it does is merging the files, but let's use it. ipset and iptables
are needed to setup the rules.

## How to block an IP

The script will read files in the rules.d directory whose name end with .list,
such as rules.d/fail2ban.list or rules.d/stopforumspam.list. It will combine
the lists using

## drop or reject

Probably better to drop because it doesn't answer the door, which is more
plausible because then the spammer doesn't know whether the IP is online or
offline. If you quickly reject, the spammer will know that someone is there
and that they don't want to talk. Plus, dropping is slower because of timeouts
so it can make spammers act slower.

## What about large lists?

I know, right. In my experience it is not such a big deal, but it is something
to keep in mind.

**I'd like to have an nftables version at some point**. The performance will
probably be better with large lists, but I need to do the following in order:

- Learn nftables (good idea).
- Make sure it doesn't mess with Docker.
