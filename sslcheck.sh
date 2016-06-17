#!/bin/bash

Alert() {
	logger -p "user.err" -t "${0##*/}" -s -- "$@"
	echo "$@" | mail -s "${0##*/} alert on $(hostname -f)" admins
}

test $# = 1 || { echo "Usage: ${0##*/} hostlist.txt"; exit 1; }
List="$1"

 Now="$(date +%s)"
Soon="$(date +%s -d 'next month')"

while read line; do
	line="${line%#*}" ; test -z "$line" && continue
	host="${line%:*}"
	port="${line#*:}" ; test "$port" = "$host" && port=443
	#echo host = $host, port = $port
	read d1 d2 <<< $(echo | openssl s_client -connect "$host:$port" 2>/dev/null | openssl x509 -noout -dates | awk -F= '{print "date +%s -d \"",$2,"\""}' | sh -)
	test "$d1" -gt "$Now"  && Alert "$host:$port is in future." "($d1, $Now)"
	test "$d2" -lt "$Now"  && Alert "$host:$port expired."      "($d2, $Now)"
	test "$d2" -lt "$Soon" && Alert "$host:$port expired soon." "($d2, $Soon)"
done < "$List"

## END ##
