#!/bin/bash
i=1
while(true)
do
	printf "This is run #$i...";
	sleep 0.5;
	printf "\033[0;32m";
	printf " \\u2713 \n";
	printf "\033[0m";
	((i+=1))
done
