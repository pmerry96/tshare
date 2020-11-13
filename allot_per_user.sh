#!/bin/bash

numusers=$(who | wc -l)
for user in $(users | grep -o -E '\w+' | sort -u -f)
do	
	echo $user
	./allot_resources.sh $user $numusers
done
