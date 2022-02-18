#!/bin/sh
xuexilaurl=$(uci get autodl.@autodl[0].xuexilaurl)
xuexilapath=$(uci get autodl.@autodl[0].xuexilapath)

curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $xuexilaurl | grep "class=\"card_bt\"" | sed 's/<h4\ class=\"card_bt\">//;s/<\/h4>//' > ${xuexilapath}/tmptitle
doctitle=$(cat ${xuexilapath}/tmptitle)

curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $xuexilaurl | grep "text-indent" | sed 's/<\/p>/\r\n    /g' | sed 's/<p\ style=\"text-indent:\ 2em;\ text-align:\ left;\">//g;s/<\/u>//g;s/<h2\ style=\"text-indent:\ 2em;\ text-align:\ left;\">//g;s/<\/a>//g;s/<\/h2>/\r\n    /g;1s/^/    /' > ${xuexilapath}/tmpaaa

cat ${xuexilapath}/tmpaaa | sed 's/<.*>//g' > $xuexilapath/$doctitle.txt

rm ${xuexilapath}/tmptitle ${xuexilapath}/tmpaaa
