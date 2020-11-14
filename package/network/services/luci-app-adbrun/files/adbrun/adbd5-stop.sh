#!/bin/sh


adbd5s=$(ps | grep adbd5 | grep -v grep | cut  -d ' ' -f1)
kill $adbd5s
