#!/bin/sh

workhour0=$(uci get autosign.@autosign[0].workhour)
workminute0=$(uci get autosign.@autosign[0].workminute)
gooffworkhour0=$(uci get autosign.@autosign[0].gooffworkhour)
gooffworkminute0=$(uci get autosign.@autosign[0].gooffworkminute)
workweek0=$(uci get autosign.@autosign[0].workweek)

echo "$workminute0 $workhour0 * * $workweek0" /usr/autosign/autosignrun.sh > /etc/crontabs/root
echo "$gooffworkminute0 $gooffworkhour0 * * $workweek0" /usr/autosign/autosignrun.sh >> /etc/crontabs/root
/etc/init.d/cron restart

