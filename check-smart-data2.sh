RED='\033[0;31m'
GRAY='\e[36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

errors=0

function get-raw-value {
	echo "${@: -1}"
}

function print-result {
	local raw_value=`get-raw-value $@`
	if [ "$raw_value" -ne 0 ]; then
		printf "${RED}[ FAIL ] "
		errors=$((errors+1))
	else
		printf "${GREEN}[ PASS ] ${GRAY}"
	fi

	printf "%3s %-22s = %3d ${NC}\n" "$1" "$2" "$raw_value"
}

function check-pass () {
	for smart_num in $@; do
		local smart_value=`grep "$smart_num" <<< "$smart_result"`
		if [ ! -z "$smart_value" ]; then
			print-result $smart_value
		fi
	done
}

function check-dev () {
	for disk in $@; do

	if [ -z "$disk" ]; then
		echo "Must specify disk device ie /dev/da0"
		exit 1
	fi

	check_dev=`grep "/dev/" <<< "$disk"`
	if [ -z "$check_dev" ]; then
		disk="/dev/$disk"
	fi

	smart_result=`sudo smartctl -a "$disk"`
	check_exists=`grep "$disk: Unable to detect device type" <<< "$smart_result"`
	if [ ! -z "$check_exists" ]; then
		echo "Cannot find device: '$disk'"
		exit 1
	fi

	echo "------------------------------------------"
	echo "Checking SMART data for $disk"
	echo "------------------------------------------"

	check-pass "5.*Reallocated_Sector_Ct" "184.*End-to-End_Error" "187.*Reported_Uncorrect" "188.*Command_Timeout" "197.*Current_Pending_Sector" "198.*Offline_Uncorrectable"


	done

	echo "------------------------------------------"
	echo "Completed with $errors errors!"
	echo "------------------------------------------"
}


function check-file () {
	for file in $@; do
	if [[ "$file" == "-f" ]]; then
		continue
	fi

	if [ ! -f "$file" ]; then
		echo "Could not find file $file"
		exit 1
	fi

	smart_result=`cat file`

	echo "------------------------------------------"
	echo "Checking SMART data for $file"
	echo "------------------------------------------"

	check-pass "5.*Reallocated_Sector_Ct" "184.*End-to-End_Error" "187.*Reported_Uncorrect" "188.*Command_Timeout" "197.*Current_Pending_Sector" "198.*Offline_Uncorrectable"

	done

	echo "------------------------------------------"
	echo "Completed with $errors errors!"
	echo "------------------------------------------"
}

if [[ "$1" == "-f"  ]]; then	
	check-file
else
	check-dev
fi

