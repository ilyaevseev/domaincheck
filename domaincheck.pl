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

 domlist="$1"
statedir="$2"

host -t any "ya.ru" || { echo "nslookup ya.ru failed" | mail -s "Domaincheck Error" admins; exit 1; }

while read dom; do
        dom=${dom%%#*}   # ..strip comments
        test -z "$dom" && continue
        for n in 1 2 3; do host -t any "$dom"; sleep 1; done \
            2>&1 | sort | uniq > "$statedir/$dom.state" || exit 1
done < "$domlist"

cd "$statedir/" || exit 1
test -d ".hg" || hg init || exit 1   # ..Requires Mercirial!

hg status | grep -q '' || exit   # ..nothing changed
( hg status ; hg diff ) | mail -s "Domaincheck report" admins
hg addremove
hg commit -m "Autocommit $(date '+%Y.%m.%d_%H:%M:%S')"