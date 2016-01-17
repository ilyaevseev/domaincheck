#!/bin/sh

test $# = 1 || { echo "Usage: $0 domain-list.txt"; exit; }

domlist="$1"   # ..textfile, one line = one domain

while read dom; do
        dom=${dom%%#*}   # ..strip comments

        # Skip empty lines, skip DENIC and com.au domains
        # See also: https://www.whois.com.au/help/knowledgebase/expiries.html#2
        case "$dom" in '' | *.de | *.com.au ) continue ;; esac

        d="$(whois $dom | awk '/[Ee]xpir.*[Dd]ate:/ || /[Tt]ill:/ {print $NF; exit;}')"
        if test -z "$d"; then
                echo "Empty expiration time for $dom" | mail -s "Whoischeck error" admins
                continue
        fi

        ds="$(date --date="$d" +%Y.%m.%d 2>/dev/null)"
        test -n "$ds" || ds="$d"   # ..workaround hack, unrecognized date may be already in "yyyy.mm.dd" format!

        if test -n "${ds##????.??.??}"; then    # ..check for "yyyy.mm.dd" format
                echo "Wrong expiration time for $dom: $d" | mail -s "Whoischeck error" admins
                continue
        fi

        #printf "%20s: %s\n" "$dom" "$ds"

        for x in `seq 0 29`; do
                soon=`date --date="+$x days" +%Y.%m.%d`
                test "$ds" = "$soon" || continue
                echo $dom: $ds | mail -s "Time to pay for domain" admins
                break;
        done
done < "$domlist"

exit 0
