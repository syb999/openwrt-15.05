#!/bin/sh

autosigngettianapikeyprefix="key="
autosigngettianapikey=$(uci get autosign.@autosign[0].tianapikey)
autosigngettiandateprefix="&type=1&date="
autosigngettiandate=$(uci get autosign.@autosign[0].tianapidate)

tmpgettianapidaytmp="${autosigngettianapikeyprefix}${autosigngettianapikey}${autosigngettiandateprefix}${autosigngettiandate}"

curl -k -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -d "$tmpgettianapidaytmp" https://apis.tianapi.com/jiejiari/index > /tmp/autosign.daytmp

sed -i 's/\"vacation\":/\n/g' /tmp/autosign.daytmp
cat /tmp/autosign.daytmp | cut -d '"' -f 2 | grep [0-9] | sed 's/|/ /g' | sed -e 's/^/ &/g' | sed -e ":a;N;s/\\n//g;ta" | sed -e 's/^[ \t]*//g' | sed -e 's/-//g' > /tmp/autosign.vacationlist
readlist=$(cat /tmp/autosign.vacationlist)
echo "$readlist" > /etc/autosignvacationlist
rm /tmp/autosign.*
