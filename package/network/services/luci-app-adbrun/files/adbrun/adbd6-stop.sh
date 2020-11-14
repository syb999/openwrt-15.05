#!/bin/sh


adbd6s=$(ps | grep adbd6 | grep -v grep | cut  -d ' ' -f1)
kill $adbd6s
