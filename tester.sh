#!/usr/bin/env bash

SCRIPT_NAME=ps2.sh
TESTER_NAME=ps2_tester
VERBOSE=1

function try {
	echo "[$i] $@"
	eval "$@"
    ret="$?"
    verbose "Return code: $ret"
    if [[ $ret != $expected_retval ]]; then
        err "Test failed. Expected return code: $expected_retval"
    fi
	echo " "
    (( i++ ))
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
i=0

expected_retval=2

verbose "Test 1 - no params"
try ./$SCRIPT_NAME

verbose "Test 4 - no name set"
try ./$SCRIPT_NAME data/sin_day_int_part.data

verbose "Test 5 - error in timeformat"
try ./$SCRIPT_NAME -t "%Y/%m/k%d" -n name data/sin_day_int_part.data

verbose "Test 6 - bad timeformat"
try ./$SCRIPT_NAME -t "%Y/%m/%d" -n name data/sin_day_int_part.data

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
try ./$SCRIPT_NAME -n PS2 -Y min -y min  -X auto -x min -v data/sin_day_part1
try ./$SCRIPT_NAME -n PS2 -Y max -y min  -x "[2009/05/11 15:24:00]" -X "[2009/30/11 07:47:00]" -v data/sin_day_part1
 # y min bigger than rendered data
try ./$SCRIPT_NAME -n PS2 -y 23.8 -v data/sin_day_part1                                                                                                       
try ./$SCRIPT_NAME -n PS2 -y -PS2 -Y auto -v data/sin_day_part1                                                                                               
try ./$SCRIPT_NAME -n PS2 -y -12 -Y -92.pp  -v data/sin_day_part1 

verbose "Test - not existing config file"
try ./$SCRIPT_NAME -f file.foo -n name data/sin_day_int_part.data

verbose "Test - Bad directive in config file"
try ./$SCRIPT_NAME -v -f data/wrong.conf data/short_date                                                                                

verbose "Test - FPS option"
try ./$SCRIPT_NAME -F 0 -n PS2 -v data/sin_day_part1
try ./$SCRIPT_NAME -F -2 -n PS2 -v data/sin_day_part1

verbose "Test - params priority"
try ./$SCRIPT_NAME  -v -x "10:30:11" -t "%H:%M:%S" -n PS2 data/short_date                                                                                     
try ./$SCRIPT_NAME  -v -X "10:30:11" -t "%H:%M:%S" -n PS2 data/short_date                                                                                      

verbose "Test - time option"
try ./$SCRIPT_NAME -T 0 -n PS2 -v data/sin_day_part1 
try ./$SCRIPT_NAME -T -2 -n PS2 -v data/sin_day_part1

verbose "Test - speed option"
try ./$SCRIPT_NAME -S 0 -n PS2 -v data/sin_day_part1          
try ./$SCRIPT_NAME -S -2 -n PS2 -v data/sin_day_part1  
try ./$SCRIPT_NAME -S 420 -n PS2 -v data/sin_day_part1

verbose "Test - EffectParam: type=anything"
try ./$SCRIPT_NAME  -v -n PS2 -e type=foo data/sin_day_part1                         
try ./$SCRIPT_NAME  -v -n PS2 -e type=foo:prom= data/sin_day_part1                         

verbose "Test - GnuplotParam: unrecognized option"
try ./$SCRIPT_NAME -v -f default.conf -e type=circles -g "rm" data/short_date

verbose "Phase 2 - correct inputs" ##-------------------------------------------------------------
i=0

expected_retval=0

verbose "Test 2 - version"
try ./$SCRIPT_NAME -V

verbose "Test 3 - help menu"
try ./$SCRIPT_NAME -h

verbose "Test - only name & data file"
try ./$SCRIPT_NAME -n "PS2" -v data/sin_day_int_part.data

verbose "Test - 2 files - in good order"
try ./$SCRIPT_NAME -n "PS2" -v data/sin_day_part1 data/sin_day_part2

verbose "Test - 2 files - in bad order"
try ./$SCRIPT_NAME -n "PS2" -v data/sin_day_part2 data/sin_day_part1

verbose "Test - 2 files - in bad order"
try ./$SCRIPT_NAME -n "PS2" -v data/sin_day_part2 data/sin_day_part1

verbose "Test - link & file - in bad order"
try ./$SCRIPT_NAME -n PS2 -v https://webdev.fit.cvut.cz/\~sokolja2/sin_day_part2 data/sin_day_part1

verbose "Test - file & link - in bad order"
try ./$SCRIPT_NAME -n PS2 -v  data/sin_day_part2 https://webdev.fit.cvut.cz/\~sokolja2/sin_day_part1


verbose "Test - min / max params"
try ./$SCRIPT_NAME -n PS2 -Y max -y min  -X max -x min -v data/sin_day_part1
try ./$SCRIPT_NAME -n PS2 -Y max -y min  -X auto -x min -v data/sin_day_part1
try ./$SCRIPT_NAME -n PS2 -Y max -y min  -X auto -x auto -v data/sin_day_part1
try ./$SCRIPT_NAME -n PS2 -Y auto -y auto  -X auto -x min -v data/sin_day_part1
try "./$SCRIPT_NAME -n PS2 -Y max -y min  -X \"[2009/05/11 15:24:00]\" -x \"[2009/05/11 07:47:00]\" -v data/sin_day_part1"
try "./$SCRIPT_NAME -n PS2 -Y max -y min  -X auto -x \"[2009/05/11 07:47:00]\" -v data/sin_day_part1"
 #switched ranges
try "./$SCRIPT_NAME -n PS2 -Y max -y min  -x \"[2009/05/11 15:24:00]\" -X \"[2009/05/11 07:47:00]\" -v data/sin_day_part1"
try "./$SCRIPT_NAME -n PS2 -Y 100 -y -5  -x \"[2009/05/11 15:24:00]\" -X \"[2009/05/11 07:47:00]\" -v data/sin_day_part1"                                            
try "./$SCRIPT_NAME -n PS2 -Y -5 -y 100  -x \"[2009/05/11 15:24:00]\" -X \"[2009/05/11 07:47:00]\" -v data/sin_day_part1"                                            
try ./$SCRIPT_NAME -n PS2 -y -10.2  -v data/sin_day_part1                                                                                                      


verbose "Test - speed option"
try ./$SCRIPT_NAME -S 0.5 -n PS2 -v data/sin_day_part1
try ./$SCRIPT_NAME -S 2 -n PS2 -v data/sin_day_part1
try ./$SCRIPT_NAME -S 12.3 -n PS2 -v data/sin_day_part1

verbose "Test - time option"
try ./$SCRIPT_NAME -T 1 -n PS2 -v data/sin_day_part1        
try ./$SCRIPT_NAME -T 0.5 -n PS2 -v data/sin_day_part1
try ./$SCRIPT_NAME -T 22 -n PS2 -v data/sin_day_part1

verbose "Test - FPS option"
try ./$SCRIPT_NAME -F 0.5 -n PS2 -v data/sin_day_part1
try ./$SCRIPT_NAME -F 2 -n PS2 -v data/sin_day_part1

verbose "Test - FPS, speed & time combined"
try ./$SCRIPT_NAME -F 20 -T 8 -n PS2 -v data/sin_day_part1
try ./$SCRIPT_NAME -F 10 -T 8 -n PS2 -v data/sin_day_part1
try ./$SCRIPT_NAME -F 80 -S 0.5 -n PS2 -v data/sin_day_part1
try ./$SCRIPT_NAME -T 12 -S 1.7 -n PS2 -v data/sin_day_part1

verbose "Test - EffectParam: type=circles"
try ./$SCRIPT_NAME  -v -n PS2 -e type=circles data/sin_day_part1                         
verbose "Test - EffectParam: type=lines"
try ./$SCRIPT_NAME -v -n PS2 -e type=lines:foo=bar:foo2=bar2 data/sin_day_part1                         

verbose "removing some of generated animations (PS2 PS2_{1..5})"
rm -r PS2 PS2_{1..5}
verbose "Next animation should be in folder PS2_$(($i+1))"

try ./$SCRIPT_NAME -n "BI-PS2" -v data/sin_day_int_part.data

verbose "Test - config file"
try ./$SCRIPT_NAME -v -f default.conf data/short_date      
verbose "Test - config & options priority"                                                                          
try ./$SCRIPT_NAME -v -f default.conf -e type=circles data/short_date
try "./$SCRIPT_NAME -v -f default.conf -e \"xformat=%H\:%M:type=circles\" -e type=lines data/short_date"
try "./$SCRIPT_NAME -v -f default.conf -e \"xformat=%H:type=circles\" -e type=lines data/short_date"

verbose "Test - name & legend with spaces"
try "./$SCRIPT_NAME -n \"BI PS2\" -l \"BI-PS2 test graph\" -v -f default.conf data/short_date"     

verbose "All test passed."
exit 0;
