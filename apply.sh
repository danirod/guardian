#!/bin/sh

set -e
cd "$(dirname $0)"

# updates the ipset list, which has the name guardian-ban.
ipset_apply() {
	generate() {
		echo "create guardian-ban hash:ip family inet hashsize 65536 maxelem 262144 --exist"
		echo flush guardian-ban
		/usr/bin/iprange --print-prefix "add guardian-ban " -1 rules.d/*.list
	}

	echo "Reloading pool of IPs..."
	generate | /usr/sbin/ipset restore
	echo "Pool of IPs successfully read and generated"
	/usr/sbin/ipset list -terse guardian-ban | grep "Number of entries"
}

# updates the firewall rules if needed.
iptables_apply() {
	exist() {
		echo "Not creating iptables rules because they already exist"
		echo "(Mistake? Please run iptables -L INPUT and manually review)"
		echo "Too risky to let the script delete iptables rules on its own"
		exit 1
	}

	/usr/sbin/iptables -L | grep -q guardian-ban && exist
	/usr/sbin/iptables -A INPUT -m set --match-set guardian-ban src -j LOG --log-prefix "[guardian-ban-ip] "
	/usr/sbin/iptables -A INPUT -m set --match-set guardian-ban src -j DROP
	echo "Firewall rules have been configured in the INPUT chain"
}

ipset_apply
iptables_apply
