#!/bin/sh
#
#  Alert on DNS domain info changing.
#
#  Requirements:
#    - commands: host, mail, hg
#    - "admins" mailbox or alias
#
#  Written by ilya.evseev@gmail.com at Aug-2014.
#

#set -x   # ..uncomment for debug!

test $# = 2 || { echo "Usage: $0 domain-list.txt /path/to/statedir/"; exit; }

 domlist="$1"   # ..textfile, one line = one domain
statedir="$2"

DNS_SERVERS="8.8.4.4  77.88.8.8  4.2.2.5"   # ..google, yandex, level3

for ns in $DNS_SERVERS; do host -t any "ya.ru" && { ns_good="yes"; break; }; done
test -n "$ns_good" || { echo "nslookup ya.ru failed" | mail -s "Domaincheck Error" admins; exit 1; }

while read dom; do
        dom=${dom%%#*}   # ..strip comments
        test -z "$dom" && continue
        for ns in $DNS_SERVERS; do
                host        "$dom" "$ns"
                host -t any "$dom" "$ns"
                host -t ns  "$dom" "$ns"
                host -t mx  "$dom" "$ns"
                sleep 1
        done 2>&1 | grep "^$dom " | sort | uniq > "$statedir/$dom.state" || exit 1
done < "$domlist"

cd "$statedir/" || exit 1
test -d ".hg" || hg init || exit 1   # ..Requires Mercirial!

hg status | grep -q '' || exit 0   # ..nothing changed
( hg status ; hg diff ) | mail -s "Domaincheck report" admins
hg addremove
hg commit -m "Autocommit $(date '+%Y.%m.%d_%H:%M:%S')"
