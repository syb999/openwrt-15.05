#!/bin/sh

pidof mpg123 > /tmp/tmpmpg123.tmp

runmpg123=$(cat /tmp/tmpmpg123.tmp)
kill $runmpg123

rm /tmp/tmpmpg123.*

