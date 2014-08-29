#!/bin/sh

(
cd /usr/local/domaincheck || exit 1

mkdir -p state logs || exit 1

./domaincheck domains.txt state > logs/$(date +%Y%m%d-%H%M%S).log 2>&1

find logs/ -type f -name '*.log' -mtime +30 -delete

) 2>&1 | mail -E -s "Domaincheck Error" admins