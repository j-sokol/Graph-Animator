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

verbose "Phase 1 - incorrect inputs" ##-------------------------------------------------------------

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

verbose "Test - min / max params"
 -n PS2 -Y min -y min  -X auto -x min -v data/sin_day_part1
 -n PS2 -Y max -y min  -x "[2009/05/11 15:24:00]" -X "[2009/30/11 07:47:00]" -v data/sin_day_part1
 # y min bigger than rendered data
 -n PS2 -y 23.8 -v data/sin_day_part1                                                                                                         2 ↵
╰─➤  ./ps4.sh -n PS2 -y -PS2 -Y auto -v data/sin_day_part1                                                                                                 2 ↵
╰─➤  ./ps4.sh -n PS2 -y -12 -Y -92.pp  -v data/sin_day_part1                                                                                               2 ↵


verbose "Phase 2 - correct inputs" ##-------------------------------------------------------------

verbose "Test - only name & data file"
try ./$SCRIPT_NAME -n "BI-PS2" -v data/sin_day_int_part.data

verbose "Test - 2 files - in good order"
try ./$SCRIPT_NAME -n "BI-PS2" -v data/sin_day_part1 data/sin_day_part2

verbose "Test - 2 files - in bad order"
try ./$SCRIPT_NAME -n "BI-PS2" -v data/sin_day_part2 data/sin_day_part1

verbose "Test - 2 files - in bad order"
try ./$SCRIPT_NAME -n "BI-PS2" -v data/sin_day_part2 data/sin_day_part1

verbose "Test - link & file - in bad order"
try ./$SCRIPT_NAME -n BI-PS2 -v https://webdev.fit.cvut.cz/\~sokolja2/sin_day_part2 data/sin_day_part1

verbose "Test - file & link - in bad order"
try ./$SCRIPT_NAME -n BI-PS2 -v  data/sin_day_part2 https://webdev.fit.cvut.cz/\~sokolja2/sin_day_part1

verbose "Test - min / max params"
 -n PS2 -Y max -y min  -X max -x min -v data/sin_day_part1
 -n PS2 -Y max -y min  -X auto -x min -v data/sin_day_part1
 -n PS2 -Y max -y min  -X auto -x auto -v data/sin_day_part1
 -n PS2 -Y auto -y auto  -X auto -x min -v data/sin_day_part1
 -n PS2 -Y max -y min  -X "[2009/05/11 15:24:00]" -x "[2009/05/11 07:47:00]" -v data/sin_day_part1
 -n PS2 -Y max -y min  -X auto -x "[2009/05/11 07:47:00]" -v data/sin_day_part1
 #switched ranges
 -n PS2 -Y max -y min  -x "[2009/05/11 15:24:00]" -X "[2009/05/11 07:47:00]" -v data/sin_day_part1
 -n PS2 -Y 100 -y -5  -x "[2009/05/11 15:24:00]" -X "[2009/05/11 07:47:00]" -v data/sin_day_part1                                             2 ↵
 -n PS2 -Y -5 -y 100  -x "[2009/05/11 15:24:00]" -X "[2009/05/11 07:47:00]" -v data/sin_day_part1                                             2 ↵
-n PS2 -y -10.2  -v data/sin_day_part1                                                                                                       2 ↵


verbose "Test - speed option"
╰─➤  ./ps4.sh -S 0 -n PS2 -v data/sin_day_part1          
╰─➤  ./ps4.sh -S -2 -n PS2 -v data/sin_day_part1                                                                                                           2 ↵
╰─➤  ./ps4.sh -S 0.5 -n PS2 -v data/sin_day_part1
╰─➤  ./ps4.sh -S 1 -n PS2 -v data/sin_day_part1
╰─➤  ./ps4.sh -S 2 -n PS2 -v data/sin_day_part1
╰─➤  ./ps4.sh -S 12.3 -n PS2 -v data/sin_day_part1
╰─➤  ./ps4.sh -S 420 -n PS2 -v data/sin_day_part1

verbose "Test - time option"
╰─➤  ./ps4.sh -T 0 -n PS2 -v data/sin_day_part1                                                                                                            2 ↵
╰─➤  ./ps4.sh -T 1 -n PS2 -v data/sin_day_part1        
╰─➤  ./ps4.sh -T -2 -n PS2 -v data/sin_day_part1
╰─➤  ./ps4.sh -T 0.5 -n PS2 -v data/sin_day_part1
╰─➤  ./ps4.sh -T 22 -n PS2 -v data/sin_day_part1

verbose "Test - params priority"


verbose "Test - FPS option"
╰─➤  ./ps4.sh -F 0 -n PS2 -v data/sin_day_part1
╰─➤  ./ps4.sh -F 0.5 -n PS2 -v data/sin_day_part1
╰─➤  ./ps4.sh -F 2 -n PS2 -v data/sin_day_part1
╰─➤  ./ps4.sh -F -2 -n PS2 -v data/sin_day_part1

verbose "Test - FPS, speed & time combined"
╰─➤  ./ps4.sh -F 20 -T 8 -n PS2 -v data/sin_day_part1
╰─➤  ./ps4.sh -F 10 -T 8 -n PS2 -v data/sin_day_part1
╰─➤  ./ps4.sh -F 80 -S 0.5 -n PS2 -v data/sin_day_part1
╰─➤  ./ps4.sh -T 12 -S 1.7 -n PS2 -v data/sin_day_part1

verbose "removing some of generated animations (PS2 PS2_{1..5})"
rm -r PS2 PS2_{1..5}
verbose "Next animation should be in folder PS2_(i+1)"

try ./$SCRIPT_NAME -n "BI-PS2" -v data/sin_day_int_part.data





