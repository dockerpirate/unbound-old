#!/bin/sh

# set timezone with TZ
# eg. TZ=America/Toronto
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# enable dnssec
/usr/sbin/unbound-anchor -a "/var/lib/unbound/root.key"

# Download the list of primary root servers.
# Unbound ships its own list but we can also download the most recent list and
# update it whenever we think it is a good idea. Note: there is no point in
# doing it more often then every 6 months.
curl https://www.internic.net/domain/named.root -o "/var/lib/unbound/root.hints"

# take full ownership of unbound lib dir since the unbound process needs write access
# fatal error: could not open autotrust file for writing, /var/lib/unbound/root.key.17-0: Permission denied
chown -R unbound:unbound "/var/lib/unbound"

# start unbound daemon
/usr/sbin/unbound -d -c "/etc/unbound/unbound.conf.d/default.conf"