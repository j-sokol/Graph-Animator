#!/usr/bin/env bash


SCRIPT_NAME='ps2.sh'
VERSION="0.1"
PARAMS="$@"
PARAMS_NO="$#"
PARAMS_ITER=0
VERBOSE=0
#set -e

function err {
     echo -e "\e[1;31m$[SCRIPT_NAME] ERROR: $@"
    exit 2
}

function cleanup {
 # rm -r "$TMP_DIR"
  verbose "Removed '$TMP_DIR' temp directory."
  exit
}


function warn {
    echo -en "\e[1;33mWARNING: \e[0m"     # print in yellow color
    for i in "$@"
    do
        echo -en "\e[1;33m$i \e[0m"       # print in yellow color 
    done
    echo ""

}

function show_usage {
    cat << EOF
    USAGE: $SCRIPT_NAME [-h] [-v] [-f config_file] [-t time_format] input_data...
    ...
    ...
EOF
}
function initialize_values {
    TIMEFORMAT='[%Y/%m/%d %H:%M:%S]'
    Y_MAX='auto'
    Y_MIN='auto'
    X_MIN='min'
    X_MAX='max'
    SPEED=1
    unset TIMEFORMAT
    EFFECTPARAMS=''
    GNUPLOTPARAMS=''
    timeregex=''
    FPS=25
}

function verbose {
    if [[ $VERBOSE -ne 0 ]]; then
        echo -en "\e[1;32m[$SCRIPT_NAME] \e[0m"
        echo "$@" >&2
    fi
}

function trim_string {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
    echo -n "$var"
}

function check_values_validity {

    timeregex="$(echo "$TIMEFORMAT" | sed 's/\\/\\\\/g; s/\./\\./g; s/\[/\\[/g; s/\]/\\]/g; s/%d/(0\[1-9\]|\[1-2\]\[0-9\]|3\[0-1\])/g; s/%H/(\[0-1\]\[0-9\]|2\[0-3\])/g; s/%I/(0\[1-9\]|1\[0-2\])/g; s/%j/(00\[1-9\]|0\[0-9\]\[0-9\]|\[1-2\]\[0-9\]\[0-9\]|3\[0-5\]\[0-9\]|36\[0-6\])/g; s/%k/(\[0-9\]|1\[0-9\]|2\[0-3\])/g; s/%l/(\[0-9\]|1\[0-2\])/g; s/%m/(0\[1-9\]|1\[0-2\])/g; s/%M/(\[0-5\]\[0-9\]|60)/g; s/%S/(\[0-5\]\[0-9\]|60)/g; s/%u/\[1-7\]/g; s/%U/(\[0-4\]\[0-9\]|5\[0-3\])/g; s/%V/(0\[1-9\]|\[1-4\]\[0-9\]|5\[0-3\])/g; s/%w/\[0-6\]/g; s/%W/(\[0-4\]\[0-9\]|5\[0-3\])/g; s/%y/\[0-9\]\[0-9\]/g; s/%Y/(\[0-1\]\[0-9\]\[0-9\]\[0-9\]|200\[0-9\]|201\[0-3\])/g;')"
    # echo "-  $timeregex  -"

    printf '%s\n' "$INPUT_DATA" | while IFS= read -r line
    do
        [[ "$(echo "$line" | cut -d, -f1)" =~ ^$timeregex$ ]] || err "Line \"$(echo "$line" | cut -d, -f1)\" does't match given dateformat. ($TIMEFORMAT) Exiting.."
        value="$(echo "$line" | cut -d, -f2)"
        [[ "$value" =~ ^-?[0-9]+$ || "$value" =~ ^-?[0-9]+\.[0-9]+$ || "$value" =~ ^\+?[0-9]+$ || "$value" =~ ^\+?[0-9]+\.[0-9]+$ ]] || err "Value \"$(echo "$line" | cut -d, -f2)\" is not a number. Exiting.."
    done
}

function load_config {

    if [ ! -z "$CONFIG_FILE" ]; then

        [ -f $CONFIG_FILE ] || err "$CONFIG_FILE is not file. Aborting."
        [ -r $CONFIG_FILE ] || err "$CONFIG_FILE is not file. Aborting."
        shopt -s extglob

        while IFS=' ' read lhs rhs
        do
            if [[ ! $lhs =~ ^\ *# && -n $lhs ]]
                then
            rhs="${rhs%%\#*}"    # Del in line right comments
            # echo "--" $lhs " = " $rhs
            lhs=`echo $lhs | tr '[:lower:]' '[:upper:]'`
            rhs=`trim_string $rhs`
            # you can test for variables to accept or other conditions here
            if [[ $lhs == *"GNUPLOTPARAMS"* ]]; then
                # echo kek $rhs
                GNUPLOTPARAMS+="set ""$rhs"$'\n'
                continue
            fi
            [ -z "${!lhs}" ] && declare "$lhs=$rhs"
        fi
    done < "$CONFIG_FILE"

fi
}


function help_menu {
    cat << EOF
    $SCRIPT_NAME, version $VERSION

    Script made as seminar work for subject BI-PS2. Creates graph animation from provided collected input data.
    Script depends on gnuplot and ffmpeg. Uses gnuplot for creating each frame in animation and then ffmpeg for combining frames into animation.
    Please read documentation for more info.

EOF
}


function load_switches {

    while getopts ":f:vhS:t:T:n:e:Y:y:X:x:g:v" opt; do
      case $opt in
        f)  CONFIG_FILE="$OPTARG"
            load_config
            (( PARAMS_ITER+=2 )) ;;
        S)  SPEED="$OPTARG" 
            [[ "$OPTARG" =~ ^\+?[1-9]([0-9])*$ || "$OPTARG" =~ ^\+?[1-9]([0-9])*\.[0-9]+$ || "$OPTARG" =~ ^\+?[0-9]+\.[1-9]([0-9])*$ || "$OPTARG" =~ ^\+?[0-9]+\.[0-9]*[1-9]$ ]] || err "Speed param bad format."
            (( PARAMS_ITER+=2 )) ;;
        T)  TIME="$OPTARG"
            echo time $TIME
            [[ "$OPTARG" =~ ^\+?[1-9]([0-9])*$ || "$OPTARG" =~ ^\+?[1-9]([0-9])*\.[0-9]+$ || "$OPTARG" =~ ^\+?[0-9]+\.[1-9]([0-9])*$ || "$OPTARG" =~ ^\+?[0-9]+\.[0-9]*[1-9]$ ]] || err "Time param bad format."
            (( PARAMS_ITER+=2 )) ;;
        F)  FPS="$OPTARG" 
            [[ "$OPTARG" =~ ^\+?[1-9]([0-9])*$ || "$OPTARG" =~ ^\+?[1-9]([0-9])*\.[0-9]+$ || "$OPTARG" =~ ^\+?[0-9]+\.[1-9]([0-9])*$ || "$OPTARG" =~ ^\+?[0-9]+\.[0-9]*[1-9]$ ]] || err "FPS param bad fmt"
            (( PARAMS_ITER+=2 )) ;;

        n)  NAME="$OPTARG"
            
            (( PARAMS_ITER+=2 )) ;;
        e)  EFFECTPARAMS="$OPTARG"
            (( PARAMS_ITER+=2 )) ;;
        v)  VERBOSE=1
            (( PARAMS_ITER++ ))  ;;
        g)  GNUPLOTPARAMS+="set ""$OPTARG"$'\n'
            (( PARAMS_ITER+=2 )) ;;
        y)  Y_MIN="$OPTARG"
            [[ "$OPTARG" =~ ^-?[0-9]+$ || "$OPTARG" =~ ^-?[0-9]+\.[0-9]+$ || "$OPTARG" =~ ^\+?[0-9]+$ || "$OPTARG" =~ ^\+?[0-9]+\.[0-9]+$ || "$OPTARG" == "auto" || "$OPTARG" == "min" ]] || err "Ymin format mismatch"

            (( PARAMS_ITER+=2 )) ;;
        Y)  Y_MAX="$OPTARG"
            [[ "$OPTARG" =~ ^-?[0-9]+$ || "$OPTARG" =~ ^-?[0-9]+\.[0-9]+$ || "$OPTARG" =~ ^\+?[0-9]+$ || "$OPTARG" =~ ^\+?[0-9]+\.[0-9]+$ || "$OPTARG" == "auto" || "$OPTARG" == "max" ]] || err "Ymax format mismatch"
            (( PARAMS_ITER+=2 )) ;;
        x)  X_MIN="$OPTARG"
            if ! [[ "$OPTARG" == "auto" || "$OPTARG" == "min" ]]; then
                [[ "$OPTARG" =~ ^$(echo "$TIMEFORMAT" | sed 's/\\/\\\\/g; s/\./\\./g; s/\[/\\[/g; s/\]/\\]/g; s/%d/(0\[1-9\]|\[1-2\]\[0-9\]|3\[0-1\])/g; s/%H/(\[0-1\]\[0-9\]|2\[0-3\])/g; s/%I/(0\[1-9\]|1\[0-2\])/g; s/%j/(00\[1-9\]|0\[0-9\]\[0-9\]|\[1-2\]\[0-9\]\[0-9\]|3\[0-5\]\[0-9\]|36\[0-6\])/g; s/%k/(\[0-9\]|1\[0-9\]|2\[0-3\])/g; s/%l/(\[0-9\]|1\[0-2\])/g; s/%m/(0\[1-9\]|1\[0-2\])/g; s/%M/(\[0-5\]\[0-9\]|60)/g; s/%S/(\[0-5\]\[0-9\]|60)/g; s/%u/\[1-7\]/g; s/%U/(\[0-4\]\[0-9\]|5\[0-3\])/g; s/%V/(0\[1-9\]|\[1-4\]\[0-9\]|5\[0-3\])/g; s/%w/\[0-6\]/g; s/%W/(\[0-4\]\[0-9\]|5\[0-3\])/g; s/%y/\[0-9\]\[0-9\]/g; s/%Y/(\[0-1\]\[0-9\]\[0-9\]\[0-9\]|200\[0-9\]|201\[0-3\])/g;')$ ]] || err "Provided timestamp format & XMAX don't match."
            fi
            (( PARAMS_ITER+=2 )) ;;
        X)  X_MAX="$OPTARG"
            if ! [[ "$OPTARG" == "auto" || "$OPTARG" == "max" ]]; then
                [[ "$OPTARG" =~ ^$(echo "$TIMEFORMAT" | sed 's/\\/\\\\/g; s/\./\\./g; s/\[/\\[/g; s/\]/\\]/g; s/%d/(0\[1-9\]|\[1-2\]\[0-9\]|3\[0-1\])/g; s/%H/(\[0-1\]\[0-9\]|2\[0-3\])/g; s/%I/(0\[1-9\]|1\[0-2\])/g; s/%j/(00\[1-9\]|0\[0-9\]\[0-9\]|\[1-2\]\[0-9\]\[0-9\]|3\[0-5\]\[0-9\]|36\[0-6\])/g; s/%k/(\[0-9\]|1\[0-9\]|2\[0-3\])/g; s/%l/(\[0-9\]|1\[0-2\])/g; s/%m/(0\[1-9\]|1\[0-2\])/g; s/%M/(\[0-5\]\[0-9\]|60)/g; s/%S/(\[0-5\]\[0-9\]|60)/g; s/%u/\[1-7\]/g; s/%U/(\[0-4\]\[0-9\]|5\[0-3\])/g; s/%V/(0\[1-9\]|\[1-4\]\[0-9\]|5\[0-3\])/g; s/%w/\[0-6\]/g; s/%W/(\[0-4\]\[0-9\]|5\[0-3\])/g; s/%y/\[0-9\]\[0-9\]/g; s/%Y/(\[0-1\]\[0-9\]\[0-9\]\[0-9\]|200\[0-9\]|201\[0-3\])/g;')$ ]] || err "Provided timestamp format & XMAX don't match."
            fi
            (( PARAMS_ITER+=2 )) ;;

        t)  TIMEFORMAT="$OPTARG"
            #[ -z "$OPTARG" ] && error "the value of the switch -t was not provided"
            [[ "$OPTARG" =~ %[dHjklmMSuUVwWyY] ]] || warn "Please check timeformat again."
            timeregex="$(echo "$TIMEFORMAT" | sed 's/\\/\\\\/g; s/\./\\./g; s/\[/\\[/g; s/\]/\\]/g; s/%d/(0\[1-9\]|\[1-2\]\[0-9\]|3\[0-1\])/g; s/%H/(\[0-1\]\[0-9\]|2\[0-3\])/g; s/%I/(0\[1-9\]|1\[0-2\])/g; s/%j/(00\[1-9\]|0\[0-9\]\[0-9\]|\[1-2\]\[0-9\]\[0-9\]|3\[0-5\]\[0-9\]|36\[0-6\])/g; s/%k/(\[0-9\]|1\[0-9\]|2\[0-3\])/g; s/%l/(\[0-9\]|1\[0-2\])/g; s/%m/(0\[1-9\]|1\[0-2\])/g; s/%M/(\[0-5\]\[0-9\]|60)/g; s/%S/(\[0-5\]\[0-9\]|60)/g; s/%u/\[1-7\]/g; s/%U/(\[0-4\]\[0-9\]|5\[0-3\])/g; s/%V/(0\[1-9\]|\[1-4\]\[0-9\]|5\[0-3\])/g; s/%w/\[0-6\]/g; s/%W/(\[0-4\]\[0-9\]|5\[0-3\])/g; s/%y/\[0-9\]\[0-9\]/g; s/%Y/(\[0-1\]\[0-9\]\[0-9\]\[0-9\]|200\[0-9\]|201\[0-3\])/g;')"
            (( PARAMS_ITER+=2 )) ;;
            # + $(grep -o " " <<< "$OPTARG" | wc -l)
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1 ;;
        h)
            # print help menu ...
            help_menu
            exit 0 ;;
        v)  
            echo $VERSION
            exit 0 ;;

esac
done

}


function load_data {
    # echo files in params locations: `seq $PARAMS_ITER $(($PARAMS_NO))`
    # [[ $(seq $PARAMS_ITER $(($PARAMS_NO - 1))) ]] || err "No files given in params."
    [ -n "$@" ] ||  err "No files given in params."
 #   IFS=' ' read -r -a INPUT_FILES <<< $@
    INPUT_DATA=""
    for INPUT_FILES in "$@"
#    for i in `seq $PARAMS_ITER $(($PARAMS_NO - 1))`
    do
        if [[ ${INPUT_FILES[i]} =~ ^http://.*$|^https://.*$ ]]; then
            verbose "Downloading file: ${INPUT_FILES[i]}"
            wget "${INPUT_FILES[i]}" -O $TMP/${SCRIPT_NAME}_$i >/dev/null 2>&1
            if [[ "$?" -eq 0 ]]; then
                verbose "File ${INPUT_FILES[i]} downloaded."
            else
                err "File ${INPUT_FILES[i]} failed to download. Exiting."
            fi
            INPUT_DATA+=`<$TMP/${SCRIPT_NAME}_$i`
            rm $TMP/${SCRIPT_NAME}_$i
        else 
            [ -f ${INPUT_FILES[i]} ] || err "${INPUT_FILES[i]} is not file. Aborting." 
            [ -r ${INPUT_FILES[i]} ] || err "${INPUT_FILES[i]} cannot be read. Aborting." 
            verbose "Reading file: ${INPUT_FILES[i]}"

            INPUT_DATA+=`<${INPUT_FILES[i]}`  

        fi

    done

    VAR_INPUT_DATA=$(echo "$INPUT_DATA"| sed 's/\(.*\) /\1,/' ) # change ws delimiter to ','
    INPUT_DATA="$VAR_INPUT_DATA"


}

function set_y_range {
    
    if [[ "$Y_MAX" == "auto" ]]; then
        Y_RANGE_END=''
    elif [[ "$Y_MAX" == "max" ]]; then
        Y_RANGE_END=$(echo "$INPUT_DATA"| awk -F "," '
        NR==1  { max=$2 }
        $2>max { max=$2 }
        END      { print max; }' ) 
    else 
        Y_RANGE_END=$Y_MAX
    fi

    if [[ "$Y_MIN" == "auto" ]]; then
        Y_RANGE_START=''
    elif [[ "$Y_MIN" == "min" ]]; then
        Y_RANGE_START=$(echo "$INPUT_DATA"| awk -F "," '
        NR==1  { min=$2 }
        $2<min { min=$2 }
        END      { print min; }' ) 
    else 
        Y_RANGE_START=$Y_MIN
    fi

    verbose "Y range is: $Y_RANGE_START -> $Y_RANGE_END"
}

function set_x_range {
    if [[ "$X_MAX" == "auto" ]]; then
        X_RANGE_END=''
    elif [[ "$X_MAX" == "max" ]]; then
        X_RANGE_END=`echo "$INPUT_DATA"|tail -n 1 |sed 's;,.*$;;'`
    else 
        X_RANGE_END=$X_MAX
    fi

    if [[ "$X_MIN" == "auto" ]]; then
        X_RANGE_START=''
    elif [[ "$X_MIN" == "min" ]]; then
        X_RANGE_START=`echo "$INPUT_DATA"|head -n 1 |sed 's;,.*$;;'`
    else 
        X_RANGE_START=$X_MIN
    fi

    verbose "X range is: $X_RANGE_START -> $X_RANGE_END"
}

function calculate_speed {
    if [ "$FPS" != "" ] && [ "$SPEED" != "" ] && [ "$TIME" != "" ]; then
        warn "FPS, speed & time are all set. Will use speed & time only."
    fi
    if [ "$SPEED" != "" ] && [ "$TIME" != "" ]; then
        verbose Lines is: "$LINES" SPEED is $SPEED time is $TIME
        frames=$((($LINES/2)/$SPEED))
        # let frames="($LINES/2)/$SPEED"
        verbose frames is $frames
        $FPS=$(($frames /$TIME))
        verbose fps is $FPS
        echo FPS: $FPS
        warn kurva
    elif [ "$FPS" != "" ] && [ "$SPEED" != "" ]; then
        echo FPS is $FPS;
    elif [  "$FPS" != "" ] && [ "$TIME" != "" ]; then
        SPEED=$((($LINES/$FPS)/$TIME))
        verbose speed set to $SPEED
    fi
}

# -------- MAIN ----------------
if [ $# -eq 0 ]; then
    warn "${SCRIPT_NAME}: No arguments provided."
    show_usage
    exit 1
fi
# clean up after exiting script
trap cleanup EXIT


# check if executables are installed ...
command -v gnuplot >/dev/null 2>&1 || err "Gnuplot doesn't seem to be installed on this machine. Please check it and run the script again. Aborting."
command -v ffmpeg >/dev/null 2>&1  || err "FFmpeg doesn't seem to be installed on this machine. Please check it and run the script again. Aborting."
command -v wget >/dev/null 2>&1    || err "Wget doesn't seem to be installed on this machine. Please check it and run the script again. Aborting."

# create tmp dir 
TMP_DIR=$(mktemp -d) || err "Not able to create temp directory. Aborting."



# initialize default consts & settings ...
initialize_values


# load configuration from params.
load_switches "$@"


 echo "============"
 echo "OPS: " $opt
 echo "OPS2: " $@
 shift `expr $OPTIND - 1`
 echo "OPS3: " $@

 echo "============"

# load config file


#( set -o posix ; set ) | less

# echo "---" $NAME
# echo PARAMS_ITER $PARAMS_ITER

# echo PARAMS $PARAMS


# if some values are still not set - set them manually

# check if FPS, speed & time is set

# calculate values, if all arent set


# load data from files
load_data "$@"




# check if loaded values are ok
check_values_validity
if [ $? != 0 ]; then
    exit 2;
fi
verbose "Dateformat in input files is valid."


#exit 1;


# echo "$INPUT_DATA"|less

LINES=`echo "$INPUT_DATA" | wc -l`
DIGITS=${#LINES}

#echo LINES $LINES DIGITS $DIGITS 

set_y_range
set_x_range
calculate_speed

verbose "Creating animation."
#X_RANGE="1:$LINES"
#echo $Y_RANGE |less


#echo $Y_RANGE |less
first=1
FRAMES=40
# create set of frames
#for (( frame=1; frame<=40; frame++ ))
for ((frame=1;frame<=LINES/2-5;frame+= $SPEED))
do
    (( p=100*frame/(LINES/2-5) ))

    (( p%10==0 && first )) && { verbose "$p% done"; first=0; }
    (( p%10 )) && first=1

    # gnuplot script
    GP=$(cat << EOF
        set terminal png
        set output "$TMP_DIR/$(printf "%0${DIGITS}d.png" "$frame")"
        set timefmt "$TIMEFORMAT"
        set xdata time
        set datafile separator ','
        set format x "%H:%M"
        set yrange [$Y_RANGE_START:$Y_RANGE_END]
        set style line 1 linewidth 3
        set xrange ["$X_RANGE_START":"$X_RANGE_END"]
        set title "$NAME"
        $GNUPLOTPARAMS
        plot '-' using 1:2:2 with lines palette t"" 
EOF
        )   

    # prepare data for one frame
    MULTIPLIER=$(echo $frame/40|bc -l)
    SELECTED_DATA=$(echo "$INPUT_DATA")
    START_LINE=$((($LINES/2) - $frame ))
    END_LINE=$((($LINES/2) + $frame ))
    #declare -p START_LINE END_LINE
    SELECTED_DATA=$(echo "$INPUT_DATA" | sed -n "${START_LINE},${END_LINE} p" )
    # call gnuplot and create frame
    if [[ $frame -gt 1 ]]; then
        printf "%s\n" "$GP" "$SELECTED_DATA" | gnuplot
        if [ $? != 0 ]; then
            err "Problem w/ gnuplot generating images."
            exit 2;
        fi


    fi
    #frame=$(($frame+$SPEED))
   # echo frame  $frame
done

if [ ! -d "$NAME" ]; then
    OUTPUT_DIR="$NAME"
else 
    DIR_FILES=`find "${NAME}"_* -maxdepth 1 -type d 2>/dev/null`
    DIR_NUM=0
    if [ -z "$DIR_FILES" ]; then 
        echo ""
    else
        for i in $DIR_FILES; do
            j=`echo $i | sed "s;${NAME}_;;"`
            if  [[ "$j" =~ ^[0-9]+$ ]] && [[ $j -gt $DIR_NUM ]] ; then
                DIR_NUM=$j
            fi
        done
    fi
    ((DIR_NUM++))
    OUTPUT_DIR="${NAME}_${DIR_NUM}"

fi



#anim="anim.mp4"
anim="${OUTPUT_DIR}/anim.mp4"
mkdir "$OUTPUT_DIR"


ffmpeg -y -r "$FPS" -i "$TMP_DIR/%0${DIGITS}d.png" "$anim" &>/dev/null || err "Error during ffmpeg execution"

verbose "Generated animation is in folder \"$anim\""
exit 0