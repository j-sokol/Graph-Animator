#!/usr/bin/env bash

SCRIPT_NAME=ps4.sh
TESTER_NAME=ps2_tester
VERBOSE=1

function try {
	echo "$@"
	$@
	verbose "Return code: $?"
	echo " "
}

function err {
    echo -e "\e[1;31m[$TESTER_NAME] ERROR: $@ \e[0m"
    exit 2
}

function verbose {
    if [[ $VERBOSE -ne 0 ]]; then
        echo -en "\e[1;32m[$TESTER_NAME] \e[0m"
        echo "$@" >&2
    fi
}

verbose "Phase 1"

verbose "Test 1 - no params"
try ./$SCRIPT_NAME

verbose "Test 2 - version"
try ./$SCRIPT_NAME -V

verbose "Test 3 - help menu"
try ./$SCRIPT_NAME -h

verbose "Test 4 - no name set"
try ./$SCRIPT_NAME data/sin_day_int_part.data

verbose "Test 5 - error in timeformat"
try ./$SCRIPT_NAME -t "%Y/%m/%d" -n name data/sin_day_int_part.data

verbose "Test 6 - bad timeformat"
try ./$SCRIPT_NAME -t "%Y/%m/%d" -n name data/sin_day_int_part.data

verbose "Test 7 - not existing config file"
try ./$SCRIPT_NAME -f file.foo -n name data/sin_day_int_part.data

verbose "Test 8 - not existing option"
try ./$SCRIPT_NAME -z -n name data/sin_day_int_part.data

verbose "Test 9 - empty data file"
try ./$SCRIPT_NAME -n name data/empty

verbose "Test 9 - bad FPS param"
try ./$SCRIPT_NAME -n name -F zz data/sin_day_int_part.data

verbose "Test 10 - not existing http link"
try ./$SCRIPT_NAME  -n name https://fjdfnsk.com/notexisting

verbose "Test 11 - not existing data file"
try ./$SCRIPT_NAME  -n name data/notexisting

verbose "Test 12 - http - permission denied"
try ./$SCRIPT_NAME  -n name https://users.fit.cvut.cz/\~barinkl/data4

verbose "Phase 2"

verbose "Test 1 - only name & data file"
try ./$SCRIPT_NAME -n "BI-PS2" -v data/sin_day_int_part.data

verbose "Test 1 - 2 files - in good order"
try ./$SCRIPT_NAME -n "BI-PS2" -v data/sin_day_part1 data/sin_day_part2

verbose "Test 1 - 2 files - in bad order"
try ./$SCRIPT_NAME -n "BI-PS2" -v data/sin_day_part2 data/sin_day_part1

verbose "Test 1 - 2 files - in bad order"
try ./$SCRIPT_NAME -n "BI-PS2" -v data/sin_day_part2 data/sin_day_part1

verbose "Test 1 - link & file - in bad order"
try ./$SCRIPT_NAME -n BI-PS2 -v https://webdev.fit.cvut.cz/\~sokolja2/sin_day_part2 data/sin_day_part1

verbose "Test 1 - file & link - in bad order"
try ./$SCRIPT_NAME -n BI-PS2 -v  data/sin_day_part2 https://webdev.fit.cvut.cz/\~sokolja2/sin_day_part1

