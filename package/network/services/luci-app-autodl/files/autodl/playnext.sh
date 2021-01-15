#!/bin/sh

pidof mpg123 > /tmp/tmpmpg123.tmp

runmpg123=$(cat /tmp/tmpmpg123.tmp)
kill $runmpg123 > /dev/null 2>&1

rm /tmp/tmpmpg123.*

