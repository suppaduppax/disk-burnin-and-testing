#!/bin/bash
RED='\033[0;31m'
GRAY='\e[36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

logfiles=$@

for logfile in $logfiles; do
	printf "+---------------------------------------------------------------------------\n"
	printf "| Reading log file: '%s'\n" "$logfile"
	printf "+---------------------------------------------------------------------------\n"
	check_finished=$(cat $logfile | grep "Finished burn-in of")
	if [ -z "$check_finished" ]; then
		drive=$(cat $logfile | grep 'Drive:' | awk '{printf $2}')
		printf "${RED}[ FAIL ] ${NC}Burn-in was not completed for '${drive}'\n"
	else
		printf "${GREEN}[ PASS ] ${NC}Burn-in completed successfully\n"
	fi
done

printf "${NC}----------------------------------------------------------------------------\n"
