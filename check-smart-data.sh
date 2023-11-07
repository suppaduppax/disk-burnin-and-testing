#!/bin/bash

RED='\033[0;31m'
GRAY='\e[36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

errors=0
fail_power_on_hours=30000
fail_bytes_written=300000 # need to verify this

function get-device-type {
	result=$(echo "${1}" | grep "Transport protocol:" | awk '{print $3}' | tr -d '\n')
	if [ -z "$result" ]; then
		result=$(echo "${1}" | grep "ATA Version is:" | awk '{print $1}' | tr -d '\n')
		if [ -z "$result" ]; then
			echo "Cannot determine device type..."
			exit 1
		fi
	fi

	echo "${result}"
}

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

function check-pass-sas () {
	read_errors=$(echo "$smart_result" | grep "read: " | awk '{print $8}' | tr -d '\n')
	write_errors=$(echo "$smart_result" | grep "write: " | awk '{print $8}' | tr -d '\n')
	verify_errors=$(echo "$smart_result" | grep "verify: " | awk '{print $8}' | tr -d '\n')
	if [ "${read_errors}" -gt 0 ]; then
		printf "${RED}[ FAIL ] "
		errors=$((errors+1))
	else
		printf "${GREEN}[ SUCCESS ] "
	fi
	printf "Read uncorrectable errors: %1s${NC}\n" "$read_errors"

	if [ "${write_errors}" -gt 0 ]; then
		printf "${RED}[ FAIL ] "
		errors=$((errors+1))
	else
		printf "${GREEN}[ SUCCESS ] "
	fi
	printf "Write uncorrectable errors: %1s${NC}\n" "${write_errors}"

	if [ "${verify_errors}" -gt 0 ]; then
		printf "${RED}[ FAIL ] "
		errors=$((errors+1))
	else
		printf "${GREEN}[ SUCCESS ] "
	fi
	printf "Verify uncorrectable errors: %1s${NC}\n" "${verify_errors}"

	power_on_hours=$(echo "$smart_result" | grep "Accumulated power on time" | sed  's/:/ /g' | awk '{print $7}' | tr -d '\n')
	if [ "${power_on_hours}" -gt "${fail_power_on_hours}" ]; then
		printf "${RED}[ FAIL ] "
		errors=$((errors+1))
	else
		printf "${GREEN}[ SUCCESS ] "
	fi
	printf "Accumulated power on hours: %1s${NC}\n" "$power_on_hours"

	bytes_written_decimal=$(cat burnin-HGST-HUH721010AL42C0_2THS6K0D.log | grep 'write:' | awk '{print $7}')
	bytes_written=$(printf "%.0f" "${bytes_written_decimal}")
	if [ "${bytes_written}" -gt "${fail_bytes_written}" ]; then
		printf "${RED}[ FAIL ] "
		errors=$((errors+1))
	else
		printf "${GREEN}[ SUCCESS ] "
	fi
	printf "Bytes written: %1s${NC}\n" "$bytes_written"

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

		smart_result=$(cat $file)
		device_type=$(get-device-type "${smart_result}")


		echo "------------------------------------------"
		echo "Checking SMART data for ${file} (${device_type})"
		echo "------------------------------------------"

		if [ "${device_type}" = SAS ]; then
			check-pass-sas
		else
			check-pass "5.*Reallocated_Sector_Ct" "184.*End-to-End_Error" "187.*Reported_Uncorrect" "188.*Command_Timeout" "197.*Current_Pending_Sector" "198.*Offline_Uncorrectable"
		fi
	done

	echo "------------------------------------------"
	echo "Completed with $errors errors!"
	echo "------------------------------------------"
}

if [[ "$1" == "-f"  ]]; then
	check-file $@
else
	check-dev
fi

