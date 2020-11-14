#!/bin/sh


adbd3s=$(ps | grep adbd3 | grep -v grep | cut  -d ' ' -f1)
kill $adbd3s
