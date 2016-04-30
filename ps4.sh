#!/usr/bin/env bash


SCRIPT_NAME='ps2.sh'
VERSION="0.1"
PARAMS="$@"
PARAMS_NO="$#"
PARAMS_ITER=0
VERBOSE=0


function err {
    for i in "$@"
    do
        echo -e "\e[1;31m$SCRIPT_NAME ERROR: $i\e[0m" >&2    # print in red color
    done

    exit 2
}

function cleanup {
  rm -r "$TMP_DIR"
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
    SPEED=1
    TIME=''
    EFFECTPARAMS=''
    GNUPLOTPARAMS=''
    timeregex=''
    FPS=25
}

function verbose {
    if [[ $VERBOSE -ne 0 ]]; then
        echo -en "\e[1;32m$SCRIPT_NAME: \e[0m"
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
    echo "-  $timeregex  -"

    printf '%s\n' "$INPUT_DATA" | while IFS= read -r line
    do
        [[ "$(echo "$line" | cut -d, -f1)" =~ ^$timeregex$ ]] || err "Line \"$(echo "$line" | cut -d, -f1)\" does't match given dateformat. ($TIMEFORMAT) Exiting.."
    done
    verbose "Dateformat in input files is valid."

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
            echo "--" $lhs " = " $rhs
            lhs=`echo $lhs | tr '[:lower:]' '[:upper:]'`
            rhs=`trim_string $rhs`
            # you can test for variables to accept or other conditions here
            if [[ $lhs == *"GNUPLOTPARAMS"* ]]; then
                echo kek $rhs
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
            [[ "$OPTARG" =~ ^\+?[1-9]([0-9])*$ || "$OPTARG" =~ ^\+?[1-9]([0-9])*\.[0-9]+$ || "$OPTARG" =~ ^\+?[0-9]+\.[1-9]([0-9])*$ || "$OPTARG" =~ ^\+?[0-9]+\.[0-9]*[1-9]$ ]] || err "Time param bad format."
            (( PARAMS_ITER+=2 )) ;;
        F)  FPS="$OPTARG" 
            [[ "$OPTARG" =~ ^\+?[1-9]([0-9])*$ || "$OPTARG" =~ ^\+?[1-9]([0-9])*\.[0-9]+$ || "$OPTARG" =~ ^\+?[0-9]+\.[1-9]([0-9])*$ || "$OPTARG" =~ ^\+?[0-9]+\.[0-9]*[1-9]$ ]] && {    # non-numeric value, should be int/float, must not be zero
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

        t)  TIMEFORMAT='$OPTARG'
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
    IFS=' ' read -r -a INPUT_FILES <<< $PARAMS
    INPUT_DATA=""
    for i in `seq $PARAMS_ITER $(($PARAMS_NO - 1))`
    do
        echo loadig file/page: ${INPUT_FILES[i]}
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
echo "No of params:" $#
echo "'@': $@"

initialize_values

load_switches "$@"


echo "============"
echo "OPS: " $opt
echo "============"

# load config file


echo "$GNUPLOTPARAMS" |less

#( set -o posix ; set ) | less

echo "---" $NAME
echo PARAMS_ITER $PARAMS_ITER

echo PARAMS $PARAMS


# if some values are still not set - set them manually

# check if FPS, speed & time is set

# calculate values, if all arent set


# load data from files
load_data

VAR_INPUT_DATA=$(echo "$INPUT_DATA"| sed 's/\(.*\) /\1,/' )
INPUT_DATA="$VAR_INPUT_DATA"



# check if loaded values are ok
check_values_validity

exit 1;


echo "$INPUT_DATA"|less

LINES=`echo "$INPUT_DATA" | wc -l`
DIGITS=${#LINES}

echo LINES $LINES DIGITS $DIGITS 
#X_RANGE="1:$LINES"
Y_RANGE=$(echo "$INPUT_DATA"| awk -F "," '
    NR==1  { min=$2; max=$2 }
    $2>max { max=$2 }
    $2<min { min=$2 }
    END      { if ( min > 0 ) print 0 ":" int(max)+1
else  print int(min)-1 ":" int(max)+1
}
' |sed 's; ;;') 
echo $Y_RANGE |less

#Y_RANGE='-1:1'
X_RANGE_START=`echo "$INPUT_DATA"|head -n 1 |sed 's;,.*$;;'`
X_RANGE_END=`echo "$INPUT_DATA"|tail -n 1 |sed 's;,.*$;;'`
echo $Y_RANGE |less
first=1
FRAMES=40
# create set of frames
#for (( frame=1; frame<=40; frame++ ))
for ((frame=1;frame<=LINES/2-5;frame++))
do
    (( p=100*frame/LINES ))

    (( p%10==0 && first )) && { verbose "$p % done"; first=0; }
    (( p%10 )) && first=1

    # gnuplot script
    GP=$(cat << EOF
        set terminal png
        set output "$TMP_DIR/$(printf "%0${DIGITS}d.png" "$frame")"
        set timefmt "$TIMEFORMAT"
        set xdata time
        set datafile separator ','
        set format x "%H:%M"
        set yrange [$Y_RANGE]
        set style line 1 linewidth 3
        set xrange ["$X_RANGE_START":"$X_RANGE_END"]
        set title "$NAME"
        $GNUPLOTPARAMS
        plot '-' using 1:2:2 with lines palette t"" 
EOF
        )   
 #   echo $(((RANDOM%200)-100))
#  !      set xrange ["[2009/05/11 07:30:00]":"[2009/05/12 07:29:00]"]


# GP=$(cat << EOF
#             set terminal png
#             set output "$TMP_DIR/$(printf "%0${DIGITS}d.png" "$frame")"
#             set xrange [$X_RANGE]
#             set yrange [$Y_RANGE]
#             plot '-' with lines t""
# EOF
# )   
  # !  set palette model RGB
  # !  rgb(r,g,b) = $((RANDOM%65000)) * int(r) + $((RANDOM%65000)) * int(g) + int(b) * $((RANDOM%65000))

  #  ! set object 1 rectangle from screen 0,0 to screen 1,1 fillcolor rgbcolor rgb  behind

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


declare -p OUTPUT_DIR

#anim="anim.mp4"
anim="${OUTPUT_DIR}/anim.mp4"
mkdir "$OUTPUT_DIR"

ffmpeg -y -r "$FPS" -i "$TMP_DIR/%0${DIGITS}d.png" "$anim" &>/dev/null || err "Error during ffmpeg execution"


exit 0