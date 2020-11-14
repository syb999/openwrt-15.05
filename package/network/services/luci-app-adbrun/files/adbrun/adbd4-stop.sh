#!/bin/sh


adbd4s=$(ps | grep adbd4 | grep -v grep | cut  -d ' ' -f1)
kill $adbd4s
