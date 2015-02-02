#!/bin/sh

test $# = 1 || { echo "Usage: $0 sitelist.txt"; exit; }

sitelist="$1"   # ..textfile, one line = one sitename

wget -SO/dev/null "http://ya.ru/" 2>&1 | grep -qi '200 OK' ||
	{ echo "ya.ru unavailable" | mail -s "Sitecheck blocked" admins; exit 1; }

while read site; do
	site=${site%%#*}   # ..strip comments
	test -z "$site" && continue
	state="$(wget -SO/dev/null "$site" 2>&1)"
	echo $state | grep -qi '200 OK' && continue
	echo $state | mail -s "Sitecheck failed: $site" admins
done < "$sitelist"
