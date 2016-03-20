#!/bin/bash


SCRIPT_NAME='ps2.sh'
VERSION="0.1"
PARAMS="$@"
PARAMS_NO="$#"
PARAMS_ITER=0
VERBOSE=0


function err {
    echo "$SCRIPT_NAME: $@" >&2
    exit 2
}

function cleanup {
    rm -r "$TMP_DIR"
    verbose "Removed '$TMP_DIR' temp directory."
    exit
}

function show_usage {
    cat << EOF
USAGE: $SCRIPT_NAME [-h] [-v] [-f config_file] [-t time_format] input_data
    ...
    ...
EOF
}

function verbose {
    if [[ $VERBOSE -ne 0 ]]; then
         echo "$SCRIPT_NAME: $@" >&2
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
# clean up after exiting script
trap cleanup EXIT

    


if [ $# -eq 0 ]; then
    echo "${SCRIPT_NAME}: No arguments provided."
    show_usage
    exit 1
fi


# check if executables are installed ...
command -v gnuplot >/dev/null 2>&1 || err "Gnuplot doesn't seem to be installed on this machine. Please check it and run the script again. Aborting."
command -v ffmpeg >/dev/null 2>&1 || err "FFmpeg doesn't seem to be installed on this machine. Please check it and run the script again. Aborting."
command -v wget >/dev/null 2>&1 || err "Wget doesn't seem to be installed on this machine. Please check it and run the script again. Aborting."

# create tmp dir 
TMP_DIR=$(mktemp -d) || err "Not able to create temp directory. Aborting."



# initialize default consts & settings ...

echo "No of params:" $#
echo "'@': $@"


while getopts ":f:vhS:T:n:e:Y:y:v" opt; do
  case $opt in
    f)  CONFIG_FILE="$OPTARG"
        (( PARAMS_ITER+=2 ))
        ;;
    S)  Speed="$OPTARG" 
        (( PARAMS_ITER+=2 ))

        ;;
    T)  Time="$OPTARG"
        (( PARAMS_ITER+=2 ))

        ;;
    n)  NAME="$OPTARG"
        (( PARAMS_ITER+=2 ))

        ;;
    e)  EffectParams="$OPTARG"
        (( PARAMS_ITER+=2 ))

        ;;
    Y)  Ymax="$OPTARG"
        (( PARAMS_ITER+=2 ))


        ;;
    v)  VERBOSE=1
        (( PARAMS_ITER++ ))

        ;;

    y)  Ymin="$OPTARG"
        (( PARAMS_ITER+=2 ))

        ;;

    \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
    h)
        # print help menu ...
        help_menu
        echo here...
        exit 0
        ;;
    v)  
        echo $VERSION
        exit 0
        ;;

  esac
echo "No of params:" $#
echo "'@': $*"
done



#load config file

if [ ! -z "$CONFIG_FILE" ]; then

    [ -f $CONFIG_FILE ] || err "$CONFIG_FILE is not file. Aborting."
    shopt -s extglob

    while IFS=' ' read lhs rhs
    do
        if [[ ! $lhs =~ ^\ *# && -n $lhs ]]
        then
            rhs="${rhs%%\#*}"    # Del in line right comments
            echo "--" $lhs " = " $rhs
            # you can test for variables to accept or other conditions here
            [ -z "${!lhs}" ] && declare "$lhs=$rhs"
        fi
    done < "$CONFIG_FILE"

fi
echo "---" $NAME
echo PARAMS_ITER $PARAMS_ITER

echo PARAMS $PARAMS


# if some values are still not set - set them manually

# check if FPS, speed & time is set

# calculate values, if all arent set


# load data from files


IFS=' ' read -r -a INPUT_FILES <<< $PARAMS
INPUT_DATA=""
for i in `seq $PARAMS_ITER $(($PARAMS_NO - 1))`
do
    echo loadig file/page: ${INPUT_FILES[i]}
    if [[ ${INPUT_FILES[i]} =~ ^http.* ]]; then
        echo "will wget this now"
        wget "${INPUT_FILES[i]}" -O $TMP/${SCRIPT_NAME}_$i >/dev/null 2>&1
        INPUT_DATA+=`<$TMP/${SCRIPT_NAME}_$i`
        rm $TMP/${SCRIPT_NAME}_$i
    else 
    [ -f ${INPUT_FILES[i]} ] || err "${INPUT_FILES[i]} is not file. Aborting." 
    INPUT_DATA+=`<${INPUT_FILES[i]}`  

    fi

done


echo "------"
echo "$INPUT_DATA" |head -n 5
echo "\n------------\n"
echo "\n------------\n"
sleep 2
LINES=`echo "$INPUT_DATA" | wc -l`
DIGITS=${#LINES}

echo LINES $LINES DIGITS $DIGITS 
X_RANGE="1:$LINES"
Y_RANGE=$(awk '
    NR==1  { min=$1; max=$1 }
    $1>max { max=$1 }
    $1<min { min=$1 }
    END      { print int(min)-1 ":" int(max)+1 }
' "$INPUT_DATA") 

    first=1
    # Vytvorit sadu snimku (policek filmu)
    for ((frame=1;frame<=LINES;frame++))
    do
        ((p=100*frame/LINES))

        ((p%10==0 && first)) && { verbose "$p % done"; first=0; }
        ((p%10)) && first=1

        # gnuplot script
GP=$(cat << EOF
            set terminal png
            set output "$TMP_DIR/$(printf "%0${DIGITS}d.png" "$frame")"
            set xrange [$X_RANGE]
            set yrange [$Y_RANGE]
            plot '-' with lines t""
EOF
)   

  #      echo "---- GP:"
  #      echo "$GP"
  #      echo "____"
        # Pripravit data pro 1 snimek
        SELECTED_DATA=$(echo "$INPUT_DATA" |head -n "$frame")
  #      echo $SELECTED_DATA
  #    sleep 1
        # Zavolat gnuplot a vytvorit snimek
        if [[ $frame -gt 1 ]]; then
        printf "%s\n" "$GP" "$SELECTED_DATA" | gnuplot
        fi

    done
    anim=hovno.mp4

    ffmpeg -y -i "$TMP_DIR/%0${DIGITS}d.png" "$anim" 2>/dev/null || err "Error during ffmpeg execution"


# check if loaded values are ok


#( set -o posix ; set ) | less


#done
echo THIS IS THE END,,,
echo "^lines of data"

exit 1

echo "FILE EXTENSION  = ${EXTENSION}"
echo "SEARCH PATH     = ${SEARCHPATH}"
echo "LIBRARY PATH    = ${LIBPATH}"
echo "Number files in SEARCH PATH with EXTENSION:" $(ls -1 "${SEARCHPATH}"/*."${EXTENSION}" | wc -l)
if [[ -n $1 ]]; then
    echo "Last line of file specified as non-opt/last argument:"
    tail -1 $1
fi