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

host -t any "ya.ru" || { echo "nslookup ya.ru failed" | mail -s "Domaincheck Error" admins; exit 1; }

while read dom; do
        dom=${dom%%#*}   # ..strip comments
        test -z "$dom" && continue
        host -t any "$dom" | sort > "$statedir/$dom.state" || exit 1
done < "$domlist"

cd "$statedir/" || exit 1
test -d ".hg" || hg init || exit 1   # ..Requires Mercirial!

st="$(hg st)"
test -z "$st" && exit
hg addremove
hg ci -m "Autocommit $(date '+%Y.%m.%d_%H:%M:%S')"
echo $st | mail -s "Domaincheck report" admins