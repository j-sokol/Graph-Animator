#!/usr/bin/env bash


SCRIPT_NAME='ps2.sh'
VERSION="0.1"
PARAMS="$@"
PARAMS_NO="$#"
PARAMS_ITER=0
VERBOSE=0
#set -e

function err {
    echo -e "\e[1;31m[$SCRIPT_NAME] ERROR: $@ \e[0m" 1>&2 # print in rec color
    exit 2
}

function cleanup {
  [ -d "$TMP_DIR" ] && rm -r "$TMP_DIR"
  verbose "Removed '$TMP_DIR' temp directory."
  exit
}

function warn {
    echo -en "\e[1;33mWARNING: \e[0m" 1>&2    # print in yellow color
    for i in "$@"
    do
        echo -en "\e[1;33m$i \e[0m" 1>&2      # print in yellow color 
    done
    echo ""
}

function show_usage {
    cat << EOF
    $SCRIPT_NAME [-v] [-V] [-h] [-l LEGEND] [-f CONFIGFILE] [-T TIME] [-F FPS] [-e EFFECTPARAMS] [-g GNUPLOTPARAMS]
    [-y YMIN] [-Y YMAX] [-x XMIN] [-X XMAX] [-t TIMEFORMAT] -n name FILE...
EOF
}

function initialize_values {
    TIMEFORMAT='[%Y/%m/%d %H:%M:%S]'
    YMAX='auto'
    YMIN='auto'
    XMIN='min'
    XMAX='max'
    SPEED=1
    EFFECTPARAMS=''
    GNUPLOTPARAMS=''
    timeregex=''
    FPS=25
    NAME=""
    LEGEND=""
    timeset=false
    speedset=false
    fpsset=false
}

function verbose {
    if [[ $VERBOSE -ne 0 ]]; then
        echo -en "\e[1;32m[$SCRIPT_NAME] \e[0m" # print in green
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

    printf '%s\n' "$INPUT_DATA" | while IFS= read -r line
    do
        [ -z "$line" ] && continue;
        [[ "$(echo "$line" | cut -d, -f1)" =~ ^$timeregex$ ]] || err "Line \"$(echo "$line" | cut -d, -f1)\" does't match given dateformat. ($TIMEFORMAT) Exiting.."
        value="$(echo "$line" | cut -d, -f2)"
        [[ "$value" =~ ^-?[0-9]+$ || "$value" =~ ^-?[0-9]+\.[0-9]+$ || "$value" =~ ^\+?[0-9]+$ || "$value" =~ ^\+?[0-9]+\.[0-9]+$ ]] || err "Value $value is not a number. Exiting.."
    done
}

function load_config {
    if [ ! -z "$CONFIG_FILE" ]; then

        [ -f $CONFIG_FILE ] || err "Configuration file $CONFIG_FILE is not file. Aborting."
        [ -r $CONFIG_FILE ] || err "Configuration file $CONFIG_FILE is not file. Aborting."
        shopt -s extglob

        while IFS=' ' read lhs rhs
        do
            if [[ ! $lhs =~ ^\ *# && -n $lhs ]] 
                then
            rhs="${rhs%%\#*}"    # delete inline right comments
            lhs=`echo $lhs | tr '[:lower:]' '[:upper:]'` # all directives are in uppercase
            rhs=`trim_string $rhs` # trim whitespaces around value of directive

            echo "${lhs}=${rhs}"


            case $lhs in
                GNUPLOTPARAMS )                 
                    GNUPLOTPARAMS+="set ""$rhs"$'\n'
                    continue
                    ;;
                LEGEND )
                    LEGEND=$(echo "$rhs" |tr -cd '[[:alnum:]] ._-')
                    continue
                    ;;
                *NAME* )
                    verbose kurva
                    NAME=$(echo "$rhs" |tr -cd '[[:alnum:]] ._-')
                    echo name is $NAME
                    continue
                    ;;

                TIMEFORMAT )
                    [[ "$rhs" =~ %[dHjklmMSuUVwWyY] ]] || warn "Directive timeformat may not be in good format ($TIMEFORMAT)."
                    verbose "value of the TimeFormat directive is: $rhs"
                    ;;
                XMIN )
                    if ! [[ "$rhs" == "auto" || "$rhs" == "min" ]]; then
                        [[ "$rhs" =~ ^$(echo "$TIMEFORMAT" | sed 's/\\/\\\\/g; s/\./\\./g; s/\[/\\[/g; s/\]/\\]/g; s/%d/(0\[1-9\]|\[1-2\]\[0-9\]|3\[0-1\])/g; s/%H/(\[0-1\]\[0-9\]|2\[0-3\])/g; s/%I/(0\[1-9\]|1\[0-2\])/g; s/%j/(00\[1-9\]|0\[0-9\]\[0-9\]|\[1-2\]\[0-9\]\[0-9\]|3\[0-5\]\[0-9\]|36\[0-6\])/g; s/%k/(\[0-9\]|1\[0-9\]|2\[0-3\])/g; s/%l/(\[0-9\]|1\[0-2\])/g; s/%m/(0\[1-9\]|1\[0-2\])/g; s/%M/(\[0-5\]\[0-9\]|60)/g; s/%S/(\[0-5\]\[0-9\]|60)/g; s/%u/\[1-7\]/g; s/%U/(\[0-4\]\[0-9\]|5\[0-3\])/g; s/%V/(0\[1-9\]|\[1-4\]\[0-9\]|5\[0-3\])/g; s/%w/\[0-6\]/g; s/%W/(\[0-4\]\[0-9\]|5\[0-3\])/g; s/%y/\[0-9\]\[0-9\]/g; s/%Y/(\[0-1\]\[0-9\]\[0-9\]\[0-9\]|200\[0-9\]|201\[0-3\])/g;')$ ]] || err "Provided timestamp format ($TIMEFORMAT) & XMIN ($rhs) don't match."
                    fi
                    verbose "value of the XMIN directive is: $rhs"
                ;;
                XMAX )
                    if ! [[ "$rhs" == "auto" || "$rhs" == "max" ]]; then
                        [[ "$rhs" =~ ^$(echo "$TIMEFORMAT" | sed 's/\\/\\\\/g; s/\./\\./g; s/\[/\\[/g; s/\]/\\]/g; s/%d/(0\[1-9\]|\[1-2\]\[0-9\]|3\[0-1\])/g; s/%H/(\[0-1\]\[0-9\]|2\[0-3\])/g; s/%I/(0\[1-9\]|1\[0-2\])/g; s/%j/(00\[1-9\]|0\[0-9\]\[0-9\]|\[1-2\]\[0-9\]\[0-9\]|3\[0-5\]\[0-9\]|36\[0-6\])/g; s/%k/(\[0-9\]|1\[0-9\]|2\[0-3\])/g; s/%l/(\[0-9\]|1\[0-2\])/g; s/%m/(0\[1-9\]|1\[0-2\])/g; s/%M/(\[0-5\]\[0-9\]|60)/g; s/%S/(\[0-5\]\[0-9\]|60)/g; s/%u/\[1-7\]/g; s/%U/(\[0-4\]\[0-9\]|5\[0-3\])/g; s/%V/(0\[1-9\]|\[1-4\]\[0-9\]|5\[0-3\])/g; s/%w/\[0-6\]/g; s/%W/(\[0-4\]\[0-9\]|5\[0-3\])/g; s/%y/\[0-9\]\[0-9\]/g; s/%Y/(\[0-1\]\[0-9\]\[0-9\]\[0-9\]|200\[0-9\]|201\[0-3\])/g;')$ ]] || err "Provided timestamp ($TIMEFORMAT) format & XMAX ($rhs) don't match."
                    fi
                    verbose "value of the XMax directive is: $rhs"
                ;;
                YMAX )
                    [[ "$rhs" =~ ^-?[0-9]+$ || "$rhs" =~ ^-?[0-9]+\.[0-9]+$ || "$rhs" =~ ^\+?[0-9]+$ || "$rhs" =~ ^\+?[0-9]+\.[0-9]+$ || "$rhs" == "auto" || "$rhs" == "max" ]] || err "Ymax is in bad format. Has to be 'auto'/'max'/'float'."
                    verbose "value of the YMax directive is: $rhs"
                ;;
                YMIN )
                    [[ "$rhs" =~ ^-?[0-9]+$ || "$rhs" =~ ^-?[0-9]+\.[0-9]+$ || "$rhs" =~ ^\+?[0-9]+$ || "$rhs" =~ ^\+?[0-9]+\.[0-9]+$ || "$rhs" == "auto" || "$rhs" == "min" ]] || err "Ymin is in bad format. Has to be 'auto'/'min'/'float'."
                    verbose "value of the YMin directive is: $rhs"
                ;;
                SPEED )
                    [[ "$rhs" =~ ^\+?[1-9]([0-9])*$ || "$rhs" =~ ^\+?[1-9]([0-9])*\.[0-9]+$ || "$rhs" =~ ^\+?[0-9]+\.[1-9]([0-9])*$ || "$rhs" =~ ^\+?[0-9]+\.[0-9]*[1-9]$ ]] || err "Parameter speed is in bad format. Has to be int/float value."
                    eval speedset=true
                ;;
                TIME )
                    [[ "$rhs" =~ ^\+?[1-9]([0-9])*$ || "$rhs" =~ ^\+?[1-9]([0-9])*\.[0-9]+$ || "$rhs" =~ ^\+?[0-9]+\.[1-9]([0-9])*$ || "$rhs" =~ ^\+?[0-9]+\.[0-9]*[1-9]$ ]] || err "Parameter time is in bad format. Has to be int/float value."
                    eval timeset=true
                ;;
                FPS )
                    [[ "$rhs" =~ ^\+?[1-9]([0-9])*$ || "$rhs" =~ ^\+?[1-9]([0-9])*\.[0-9]+$ || "$rhs" =~ ^\+?[0-9]+\.[1-9]([0-9])*$ || "$rhs" =~ ^\+?[0-9]+\.[0-9]*[1-9]$ ]] || err "Parameter FPS is in bad format ($FPS). Has to be int/float value."
                    eval fpsset=true
                ;;
                * )
                    continue ;;
            esac
            echo "${lhs}=${rhs}"
            eval $lhs="$rhs"
        fi
        done < "$CONFIG_FILE"
    fi
}

function help_menu {
    cat << EOF
    $SCRIPT_NAME, version $VERSION

    Bash script that creates a .mp4 animation from source (sources) of data - URLs or files. 
    Input data in files are in format "Date [ws] float value", eg. "[2009/05/11 07:33:00] 5".
    Script depends on gnuplot, wget and ffmpeg.        
    Uses gnuplot for creating each frame in animation and then ffmpeg for combining frames into animation.
EOF
}
function load_switches {

    while getopts ":f:F:vVhS:t:T:n:e:Y:y:X:x:g:vl:" opt; do
      case $opt in
        l)  LEGEND=$(echo "$OPTARG" |tr -cd '[[:alnum:]] ._-')
            ;;
        f)  
            CONFIG_FILE="$OPTARG"
             ;;
        S)  SPEED="$OPTARG" 
            [[ "$OPTARG" =~ ^\+?[1-9]([0-9])*$ || "$OPTARG" =~ ^\+?[1-9]([0-9])*\.[0-9]+$ || "$OPTARG" =~ ^\+?[0-9]+\.[1-9]([0-9])*$ || "$OPTARG" =~ ^\+?[0-9]+\.[0-9]*[1-9]$ ]] || err "Parameter speed is in bad format. Has to be int/float value."
            eval speedset=true
            ;;
        T)  TIME="$OPTARG"
            [[ "$OPTARG" =~ ^\+?[1-9]([0-9])*$ || "$OPTARG" =~ ^\+?[1-9]([0-9])*\.[0-9]+$ || "$OPTARG" =~ ^\+?[0-9]+\.[1-9]([0-9])*$ || "$OPTARG" =~ ^\+?[0-9]+\.[0-9]*[1-9]$ ]] || err "Parameter time is in bad format. Has to be int/float value."
            eval timeset=true
            ;;
        F)  FPS="$OPTARG" 
            [[ "$OPTARG" =~ ^\+?[1-9]([0-9])*$ || "$OPTARG" =~ ^\+?[1-9]([0-9])*\.[0-9]+$ || "$OPTARG" =~ ^\+?[0-9]+\.[1-9]([0-9])*$ || "$OPTARG" =~ ^\+?[0-9]+\.[0-9]*[1-9]$ ]] || err "Parameter FPS is in bad format. Has to be int/float value."
            eval fpsset=true
            ;;
        n)  NAME=$(echo "$OPTARG" |tr -cd '[[:alnum:]] ._-') ;;
            
        e)  EFFECTPARAMS="$OPTARG" ;;
        v)  VERBOSE=1 
            verbose "Verbose mode enabled." ;;
        g)  GNUPLOTPARAMS+="set ""$OPTARG"$'\n' ;;
        y)  YMIN="$OPTARG"
            [[ "$OPTARG" =~ ^-?[0-9]+$ || "$OPTARG" =~ ^-?[0-9]+\.[0-9]+$ || "$OPTARG" =~ ^\+?[0-9]+$ || "$OPTARG" =~ ^\+?[0-9]+\.[0-9]+$ || "$OPTARG" == "auto" || "$OPTARG" == "min" ]] || err "Ymin is in bad format. Has to be 'auto'/'min'/'float'."
            ;;
        Y)  YMAX="$OPTARG"
            [[ "$OPTARG" =~ ^-?[0-9]+$ || "$OPTARG" =~ ^-?[0-9]+\.[0-9]+$ || "$OPTARG" =~ ^\+?[0-9]+$ || "$OPTARG" =~ ^\+?[0-9]+\.[0-9]+$ || "$OPTARG" == "auto" || "$OPTARG" == "max" ]] || err "Ymax is in bad format. Has to be 'auto'/'max'/'float'."
            ;;
        x)  XMIN="$OPTARG"
            if ! [[ "$OPTARG" == "auto" || "$OPTARG" == "min" ]]; then
                [[ "$OPTARG" =~ ^$(echo "$TIMEFORMAT" | sed 's/\\/\\\\/g; s/\./\\./g; s/\[/\\[/g; s/\]/\\]/g; s/%d/(0\[1-9\]|\[1-2\]\[0-9\]|3\[0-1\])/g; s/%H/(\[0-1\]\[0-9\]|2\[0-3\])/g; s/%I/(0\[1-9\]|1\[0-2\])/g; s/%j/(00\[1-9\]|0\[0-9\]\[0-9\]|\[1-2\]\[0-9\]\[0-9\]|3\[0-5\]\[0-9\]|36\[0-6\])/g; s/%k/(\[0-9\]|1\[0-9\]|2\[0-3\])/g; s/%l/(\[0-9\]|1\[0-2\])/g; s/%m/(0\[1-9\]|1\[0-2\])/g; s/%M/(\[0-5\]\[0-9\]|60)/g; s/%S/(\[0-5\]\[0-9\]|60)/g; s/%u/\[1-7\]/g; s/%U/(\[0-4\]\[0-9\]|5\[0-3\])/g; s/%V/(0\[1-9\]|\[1-4\]\[0-9\]|5\[0-3\])/g; s/%w/\[0-6\]/g; s/%W/(\[0-4\]\[0-9\]|5\[0-3\])/g; s/%y/\[0-9\]\[0-9\]/g; s/%Y/(\[0-1\]\[0-9\]\[0-9\]\[0-9\]|200\[0-9\]|201\[0-3\])/g;')$ ]] || err "Provided timestamp format & XMAX don't match."
            fi
            ;;
        X)  XMAX="$OPTARG"
            if ! [[ "$OPTARG" == "auto" || "$OPTARG" == "max" ]]; then
                [[ "$OPTARG" =~ ^$(echo "$TIMEFORMAT" | sed 's/\\/\\\\/g; s/\./\\./g; s/\[/\\[/g; s/\]/\\]/g; s/%d/(0\[1-9\]|\[1-2\]\[0-9\]|3\[0-1\])/g; s/%H/(\[0-1\]\[0-9\]|2\[0-3\])/g; s/%I/(0\[1-9\]|1\[0-2\])/g; s/%j/(00\[1-9\]|0\[0-9\]\[0-9\]|\[1-2\]\[0-9\]\[0-9\]|3\[0-5\]\[0-9\]|36\[0-6\])/g; s/%k/(\[0-9\]|1\[0-9\]|2\[0-3\])/g; s/%l/(\[0-9\]|1\[0-2\])/g; s/%m/(0\[1-9\]|1\[0-2\])/g; s/%M/(\[0-5\]\[0-9\]|60)/g; s/%S/(\[0-5\]\[0-9\]|60)/g; s/%u/\[1-7\]/g; s/%U/(\[0-4\]\[0-9\]|5\[0-3\])/g; s/%V/(0\[1-9\]|\[1-4\]\[0-9\]|5\[0-3\])/g; s/%w/\[0-6\]/g; s/%W/(\[0-4\]\[0-9\]|5\[0-3\])/g; s/%y/\[0-9\]\[0-9\]/g; s/%Y/(\[0-1\]\[0-9\]\[0-9\]\[0-9\]|200\[0-9\]|201\[0-3\])/g;')$ ]] || err "Provided timestamp format & XMAX don't match."
            fi
            ;;
        t)  TIMEFORMAT="$OPTARG"
            [[ "$OPTARG" =~ %[dHjklmMSuUVwWyY] ]] || warn "Directive timeformat may not be in good format ($TIMEFORMAT)."
            timeregex="$(echo "$TIMEFORMAT" | sed 's/\\/\\\\/g; s/\./\\./g; s/\[/\\[/g; s/\]/\\]/g; s/%d/(0\[1-9\]|\[1-2\]\[0-9\]|3\[0-1\])/g; s/%H/(\[0-1\]\[0-9\]|2\[0-3\])/g; s/%I/(0\[1-9\]|1\[0-2\])/g; s/%j/(00\[1-9\]|0\[0-9\]\[0-9\]|\[1-2\]\[0-9\]\[0-9\]|3\[0-5\]\[0-9\]|36\[0-6\])/g; s/%k/(\[0-9\]|1\[0-9\]|2\[0-3\])/g; s/%l/(\[0-9\]|1\[0-2\])/g; s/%m/(0\[1-9\]|1\[0-2\])/g; s/%M/(\[0-5\]\[0-9\]|60)/g; s/%S/(\[0-5\]\[0-9\]|60)/g; s/%u/\[1-7\]/g; s/%U/(\[0-4\]\[0-9\]|5\[0-3\])/g; s/%V/(0\[1-9\]|\[1-4\]\[0-9\]|5\[0-3\])/g; s/%w/\[0-6\]/g; s/%W/(\[0-4\]\[0-9\]|5\[0-3\])/g; s/%y/\[0-9\]\[0-9\]/g; s/%Y/(\[0-1\]\[0-9\]\[0-9\]\[0-9\]|200\[0-9\]|201\[0-3\])/g;')"
            ;;
        \?)
            err "Invalid option: -$OPTARG"
            exit 1 ;;
        h)
            help_menu
            exit 0 ;;
        V)  
            echo $VERSION
            exit 0 ;;
        esac
    done
    }

function load_data {
    i=0
    [[ -z "$@" ]] &&  err "No files given in params."
    INPUT_DATA=""
    for INPUT_FILES in "$@"
    do 
        if [[ ${INPUT_FILES} =~ ^http://.*$|^https://.*$ ]]; then 
            # regex match to http link
            verbose "Downloading file: ${INPUT_FILES}"
            wgeterr=$(wget "${INPUT_FILES}" -O $TMP/${SCRIPT_NAME}_$i 2>&1)
            if [[ "$?" -eq 0 ]]; then
                verbose "File ${INPUT_FILES} downloaded."
            else
                err "File ${INPUT_FILES} failed to download. Wget output: `trim_string $wgeterr` Exiting."
            fi

            [ -r $TMP/${SCRIPT_NAME}_$i ] || err "${INPUT_FILES} cannot be read. Aborting." 
            [ -s $TMP/${SCRIPT_NAME}_$i ] || err "${INPUT_FILES} is empty. Aborting." 
            # change ws delimiter to ','
            VAR_INPUT_DATA=$(sed 's/\(.*\) /\1,/' $TMP/${SCRIPT_NAME}_$i) 

            old_date=$(date -d  "`echo ${INPUT_DATA%%$'\n'*}| cut -d"," -f1 |sed 's;[^([:alnum:]|[:space:]|:)/]\+;;g'`" +%s)
            new_date=$(date -d  "`echo ${VAR_INPUT_DATA%%$'\n'*}| cut -d"," -f1| sed 's;[^([:alnum:]|[:space:]|:)/]\+;;g'`" +%s)

            if [ "$new_date" -gt "$old_date" ]; then
                INPUT_DATA+=$'\n'
                INPUT_DATA="${INPUT_DATA}${VAR_INPUT_DATA}"
            else
                [ -n "$INPUT_DATA" ] && VAR_INPUT_DATA+=$'\n'
                INPUT_DATA="${VAR_INPUT_DATA}${INPUT_DATA}"
            fi

            rm $TMP/${SCRIPT_NAME}_$i
            (( i++ ))
        else 
            # input file is regular file
            [ -f "${INPUT_FILES}" ] || err "${INPUT_FILES} is not file. Aborting." 
            [ -r "${INPUT_FILES}" ] || err "${INPUT_FILES} cannot be read. Aborting." 
            [ -s "${INPUT_FILES}" ] || err "${INPUT_FILES} is empty. Aborting." 
            verbose "Reading input file: ${INPUT_FILES}"
            # change ws delimiter to ','
            VAR_INPUT_DATA=$(sed 's/\(.*\) /\1,/' "${INPUT_FILES}") 

            old_date=$(date -d  "`echo ${INPUT_DATA%%$'\n'*}| cut -d"," -f1 |sed 's;[^([:alnum:]|[:space:]|:)/]\+;;g'`" +%s)
            new_date=$(date -d  "`echo ${VAR_INPUT_DATA%%$'\n'*}| cut -d"," -f1| sed 's;[^([:alnum:]|[:space:]|:)/]\+;;g'`" +%s)

            if [ "$new_date" -gt "$old_date" ]; then
                INPUT_DATA+=$'\n'
                INPUT_DATA="${INPUT_DATA}${VAR_INPUT_DATA}"
            else
                [ -n "$INPUT_DATA" ] && VAR_INPUT_DATA+=$'\n'
                INPUT_DATA="${VAR_INPUT_DATA}${INPUT_DATA}"
            fi
        fi
    done
}

function check_variables_set {
    [ -z "$NAME" ] && err "Directive NAME is not set. Exiting..."
}

function set_y_range {
    
    if [[ "$YMAX" == "auto" ]]; then
        Y_RANGE_END=''
    elif [[ "$YMAX" == "max" ]]; then
        Y_RANGE_END=$(echo "$INPUT_DATA"| awk -F "," '
        NR==1  { max=$2 }
        $2>max { max=$2 }
        END      { print max; }' ) 
    else 
        Y_RANGE_END=$YMAX
    fi

    if [[ "$YMIN" == "auto" ]]; then
        Y_RANGE_START=''
    elif [[ "$YMIN" == "min" ]]; then
        Y_RANGE_START=$(echo "$INPUT_DATA"| awk -F "," '
        NR==1  { min=$2 }
        $2<min { min=$2 }
        END      { print min; }' ) 
    else 
        Y_RANGE_START=$YMIN
    fi
    verbose "Range on Y axis configured to: $Y_RANGE_START : $Y_RANGE_END"
}

function set_x_range {
    if [[ "$XMAX" == "auto" ]]; then
        X_RANGE_END=''
    elif [[ "$XMAX" == "max" ]]; then
        X_RANGE_END=`echo "$INPUT_DATA"|tail -n 1 |sed 's;,.*$;;'`
    else 
        X_RANGE_END=$XMAX
    fi

    if [[ "$XMIN" == "auto" ]]; then
        X_RANGE_START=''
    elif [[ "$XMIN" == "min" ]]; then
        X_RANGE_START=`echo "$INPUT_DATA"|head -n 1 |sed 's;,.*$;;'`
    else 
        X_RANGE_START=$XMIN
    fi
    verbose "Range on X axis configured to: $X_RANGE_START : $X_RANGE_END"
}

function calculate_speed {

    if [ "$fpsset" == "true" ] && [ "$speedset" == "true" ] && [ "$timeset" == "true" ]; then
        warn "FPS, speed & time are all set. Will use speed & time only."
    fi

    if [ "$speedset" == "true" ] && [ "$timeset" == "true" ]; then
        FPS=$(echo "($LINES/2)/($SPEED*$TIME)" | bc -l | awk '{printf "%.3f\n", $0}')
    elif [ "$fpsset" == "true" ] && [ "$speedset" == "true" ]; then
        TIME=$(echo "(($LINES/2)/$FPS)/$SPEED" | bc -l | awk '{printf "%.3f\n", $0}')
    elif [  "$fpsset" == "true" ] && [ "$timeset" == "true" ]; then
        SPEED=$(echo "($LINES/2)/($FPS*$TIME)" | bc -l | awk '{printf "%.3f\n", $0}')
    elif [ "$timeset" == "true" ]; then
        FPS=$(echo "($LINES/2)/($SPEED*$TIME)" | bc -l | awk '{printf "%.3f\n", $0}')                
    elif [ "$fpsset" == "true" ]; then
        TIME=$(echo "($LINES/2)/$FPS" | bc -l | awk '{printf "%.3f\n", $0}')
    elif [ "$speedset" == "true" ]; then
        TIME=$(echo "($LINES/2)/$FPS" | bc -l | awk '{printf "%.3f\n", $0}')
    fi

    verbose "Speed values are:"
    verbose "Speed: $SPEED"
    verbose "FPS: $FPS"
    verbose "Time: $TIME"
}

# --------------- MAIN ----------------

if [ $# -eq 0 ]; then
    show_usage
    err "No arguments provided."
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

#  check if config file was passed in params & load data from it 
IFS=' ' read -r -a parameters <<< "$@"
for i in "${!parameters[@]}" ;do
    if [[ ${parameters[$i]} =~ -f ]]; then
        CONFIG_FILE=${parameters[$i+1]}
        # if so, load data from configuration file
        load_config
    fi
done

# load configuration from params.
load_switches "$@"

( set -o posix ; set ) | less

check_variables_set

# shift $@ so there are only input files left
shift `expr $OPTIND - 1` 

# load data from files
load_data "$@"

# check if loaded values are ok
check_values_validity
[ $? == 0 ] || exit 3;
verbose "Dateformat in input files is valid."

# get number of lines in input_data & digits
LINES=`echo "$INPUT_DATA" | wc -l`
DIGITS=${#LINES}

set_y_range
set_x_range
calculate_speed

verbose "Creating animation."

first=1
frame=1
iter=1
frames=$(echo "$LINES/2-1" |bc -l)

if [[ "$(echo "$SPEED>$frames" | bc -l)" == "1" ]]; then
    err "Speed is bigger than number of frames. Only 1 frame with no plots would be rendered. Exiting."
fi
while [[ "$(echo "$iter<$frames" | bc -l)" == "1" ]]; do

    # get first & last line of data rendered in this cycle
    START_LINE=$((($LINES/2) - $(printf "%.0f" $iter) ))
    END_LINE=$((($LINES/2) + $(printf "%.0f" $iter) ))

    # cut selected data 
    SELECTED_DATA=$(echo "$INPUT_DATA" | sed -n "${START_LINE},${END_LINE} p" )

    # if XMIN / XMAX set to auto - ranges have to be calculated every cycle
    if [[ "$XMAX" == "auto" ]]; then
        X_RANGE_END=`echo "$SELECTED_DATA"|tail -n 1 |sed 's;,.*$;;'`
    fi
    if [[ "$XMIN" == "auto" ]]; then
        X_RANGE_START=`echo "$SELECTED_DATA"|head -n 1 |sed 's;,.*$;;'`
    fi

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
        set title "$LEGEND"
        $GNUPLOTPARAMS
        plot '-' using 1:2:2 with lines palette t"" 
EOF
        )   


    # render frames from data using gnuplot
    ploterr=$(printf "%s\n" "$GP" "$SELECTED_DATA" | gnuplot 2>&1)
    if [ $? != 0 ]; then
        err "Problem with gnuplot generating images. Gnuplot output: `trim_string $ploterr`"
        exit 4;
    fi

    (( frame++ ))
    (( p=100*$(printf "%.0f" $iter)/(LINES/2-1) ))

    (( p%10==0 && first )) && { verbose "$p% done"; first=0; }
    (( p%10 )) && first=1

    iter=$(echo "$iter+$SPEED" | bc -l | awk '{printf "%.3f\n", $0}')
done

verbose "100% done"


# create directory for animation 
DIR_FILES=`find "${NAME}"_* -maxdepth 1 -type d 2>/dev/null`
if [ ! -d "$NAME" ] && [ -z "$DIR_FILES" ]; then
    OUTPUT_DIR="$NAME"
else 
    DIR_NUM=0
    if [ ! -z "$DIR_FILES" ]; then 
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

anim="${OUTPUT_DIR}/anim.mp4"
mkdir "$OUTPUT_DIR"

ffmpeg -y -r "$FPS" -i "$TMP_DIR/%0${DIGITS}d.png" "$anim" &>/dev/null || err "Error during ffmpeg execution"

verbose "Generated animation is in folder \"$anim\""

vlc "$anim"

exit 0
