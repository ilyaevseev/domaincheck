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
nameservers="8.8.4.4  4.2.2.6  77.88.8.8"   #..google, level3, yandex

# Is Internet connectivity alive? Fail if not..
for ns in $nameservers; do
        host -t any "ya.ru" "$ns" && continue
        echo "nslookup ya.ru via $ns failed" | mail -s "Domaincheck Error" admins
        exit 1
done

while read dom; do
        dom=${dom%%#*}   # ..strip comments
        test -z "$dom" && continue
        for ns in $nameservers; do host -t any "$dom" "$ns"; sleep 1; done \
            2>&1 | sort | uniq > "$statedir/$dom.state" || exit 1
done < "$domlist"

cd "$statedir/" || exit 1
test -d ".hg" || hg init || exit 1   # ..Requires Mercirial!

hg status | grep -q '' || exit   # ..nothing changed
( hg status ; hg diff ) | mail -s "Domaincheck report" admins
hg addremove
hg commit -m "Autocommit $(date '+%Y.%m.%d_%H:%M:%S')"
