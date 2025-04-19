#!/bin/sh

filecount=$(cat /tmp/filecount.onlineplay)
mpg123 /tmp/online$filecount.mp3

