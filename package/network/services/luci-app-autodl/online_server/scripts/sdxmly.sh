#!/bin/sh

echo $1 | sed "s/[ \'//g;s/\' ]//g" | tr -d '[]' > /tmp/sdcode.tmp
