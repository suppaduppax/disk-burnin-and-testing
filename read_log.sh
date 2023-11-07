RED='\033[0;31m'
GRAY='\e[36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

logfiles=$@

for logfile in $logfiles; do
	echo "---------------------------------"
	echo "Reading log file: '$logfile'"
	check_finished=`cat $logfile | grep "Finished burn-in of"`
	if [ -z "$check_finished" ]; then
		idline=`cat $logfile | grep "Serial Number: "`
		if [ ! -z "$idline" ]; then
			id=`grep -o "[^ ]*$" <<< $idline`
			echo -e "${RED}[ FAIL ] ${NC}Burn-in was not completed for '$id'"
			find_id=`geom disk list | grep -B 8 "ident: $id"`
			if [ ! -z "$find_id" ]; then 
				dev=`grep "Name: " <<< $find_id | grep -o "[^ ]*$"`
				echo -e "Disk is currently connected: '$dev'"
			fi
		fi
	else
		echo -e "${GREEN}[ PASS ] ${NC}Burn-in completed successfully"
	fi
done
	echo -e "${NC}---------------------------------"
