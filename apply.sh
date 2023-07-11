#!/bin/sh

set -e
cd "$(dirname $0)"

# updates the ipset list, which has the name guardian-ban-ipv4
ipset_apply_ipv4() {
	generate() {
		echo "create guardian-ban-ipv4 hash:ip family inet hashsize 65536 maxelem 262144 --exist"
		echo flush guardian-ban-ipv4
		/usr/bin/iprange --print-prefix "add guardian-ban-ipv4 " -1 rules-ipv4.d/*.list
	}

	echo "Reloading pool of IPs for IPv4..."
	generate | /usr/sbin/ipset restore
	echo "Pool of IPs for IPv4 successfully read and generated"
	/usr/sbin/ipset list -terse guardian-ban-ipv4 | grep "Number of entries"
}

# updates the ipset list which has the name guardian-ban-ipv6
ipset_apply_ipv6() {
	generate() {
		echo "create guardian-ban-ipv6 hash:ip family inet6 hashsize 65536 maxelem 262144 --exist"
		echo flush guardian-ban-ipv6
		# no support for ipv6 in iprange, so we do this manually
		cat rules-ipv6.d/*.list | sort -h | uniq | sed 's/^/add guardian-ban-ipv6 /'
	}

	echo "Reloading pool of IPs for IPv6..."
	generate | /usr/sbin/ipset restore
	echo "Pool of IPs for IPv6 successfully read and generated"
	/usr/sbin/ipset list -terse guardian-ban-ipv6 | grep "Number of entries"
}

# updates the firewall rules if needed.
iptables_apply() {
	apply_ipv4() {
		echo "Applying rules for IPv4"
		/usr/sbin/iptables -A INPUT -m set --match-set guardian-ban-ipv4 src -j LOG --log-prefix "[guardian-ban-ip] "
		/usr/sbin/iptables -A INPUT -m set --match-set guardian-ban-ipv4 src -j REJECT
		echo "Firewall rules for IPv4 have been configured in the INPUT chain"
	}

	apply_ipv6() {
		echo "Applying rules for IPv6"
		/usr/sbin/ip6tables -A INPUT -m set --match-set guardian-ban-ipv6 src -j LOG --log-prefix "[guardian-ban-ip] "
		/usr/sbin/ip6tables -A INPUT -m set --match-set guardian-ban-ipv6 src -j REJECT
		echo "Firewall rules for IPv6 have been configured in the INPUT chain"
	}

	skip_ipv4() {
		echo "Skipping rules for IPv4 because something seems to exist"
	}

	skip_ipv6() {
		echo "Skipping rules for IPv6 because something seems to exist"
	}

	/usr/sbin/iptables -L | grep -q guardian-ban && skip_ipv4 || apply_ipv4
	/usr/sbin/ip6tables -L | grep -q guardian-ban && skip_ipv6 || apply_ipv6
}

ipset_apply_ipv4
ipset_apply_ipv6
iptables_apply
