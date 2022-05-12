#!/bin/bash

function printll() {
        i=1
        while [ ${i} -lt $1 ]
        do
                let i++
                printf " "
        done

        echo $2
}

width=20
file="/tmp/csm.run.text"

while read line
do
	len=${#line}
	let w=(${width}-${len})/2
	printll ${w} "${line}" >> /tmp/csm.run.showmeit
done < ${file}


