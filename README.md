NAME

    ps2.sh - Script that creates animation of gnuplot frames from plaintext input files.

SYNOPSIS

    ps2.sh [-v] [-V] [-h] [-l LEGEND] [-f CONFIGFILE] [-S SPEED] [-T TIME] [-F FPS] [-e EFFECTPARAMS] [-g GNUPLOTPARAMS] [-y YMIN] [-Y YMAX] [-x XMIN] [-X XMAX] [-t TIMEFORMAT] -n name FILE...

DESCRIPTION

    Bash script that creates a .mp4 animation from source (sources) of data - URLs or files. Input data in files are in format "Date [ws] float value", eg. "[2009/05/11 07:33:00] 5". Script depends on gnuplot and ffmpeg. Uses gnuplot for creating each frame in animation and then ffmpeg for combining frames into animation.

OPTIONS

    -v               Verbose mode. Causes script to print messages about its progress. It is helpful when debuging problems.
    -V               Display the number version and exit.
    -h               Output a short summary of available command line options.
    -l LEGEND        Name of the graph shown in animation. All characters in legend except :alnum: and ' _.-' will be removed.
    -f CONFIGFILE    Uses the directives in the file config on startup.
    -T TIME          Duration in seconds how long animation should be. Float/int, not set by default.
    -F FPS           Frames per second passed to ffpmpeg. Value is float/int. Defaults to '25'.
    -S SPEED         Speed of animation. Value is float/int. Defaults to '1'.
    -e EFFECTPARAMS  Allowed to be used multiple times. 
                      Multiple directives can be set here:
                        type:  the style of graph to be rendered. Options are 'circles' or 'lines'. Defaults to 'lines'.
                        xformat: (strftime(3c)) Time format to be shown on X axis on graph. Defaults to '%H:%M'.
    -g GNUPLOTPARAMS Effects for gnuplot. Allowed to be used multiple times. 
    -y YMIN          Lower range value on the X axis. Has to be set to 'auto', 'min', or fixed float/int value. Defaults to 'auto'.
    -Y YMAX          Upper range value on the X axis. Has to be set to 'auto', 'max', or fixed float/int value. Defaults to 'auto'.
    -x XMIN          Lower range value on the X axis. Has to be set to 'auto', 'min', or date, matching format in option TIMEFORMAT. Defaults to 'min'.
    -X XMAX          Upper range value on the X axis. Has to be set to 'auto', 'max', or date, matching format in option TIMEFORMAT. Defaults to 'max'. 
    -t TIMEFORMAT    Strftime(3c) format. Value is set by default to "[%Y-%m-%d %H:%M:%S]".
    -n NAME          Name of the directory where animation will be saved. If there is already directory with same name, new folder will be created with suffix "_i", where i=max(i,0)+1. All characters from name  except :alnum: and ' _.-' will be removed.

CONFIG FILE
    
    The file is plain ASCII text, with columns separated by spaces or tab characters. The first column specifies name of directive. Second column describes value of given directive.
    
    Notes:
        Text starting with '#' is comment from this character to the end of line.
        Only one directive may be on one line.
        Config file is case-insensitive.
        Directive is one word only.
        If directive can be used only once, value of last appearance will be used.
    
    Folowing directives are understood by script:

    (name)     ...  (description)       (format)            (default value)
    ---------------------------------------------------------------------------
    TimeFormat ...  timestamp format    strftime(3c)        [%Y-%m-%d %H:%M:%S]
    Xmax       ...  x-max               „auto“,“max“,value  max 
    Xmin       ...  x-min               „auto“,“min“,value  min 
    Ymax       ...  y-max               „auto“,“max“,value  auto
    Ymin       ...  y-min               „auto“,“min“,value  auto 
    Speed      ...  speed               int/float           1 record/frame 
    Time       ...  time (duration)     int/float           n/a
    FPS        ...  fps                 int/float           25 
    Legend     ...  legend              text                n/a 
    GnuplotParams   gnuplot params*     parameter           n/a 
    EffectParams    effect params*      param=val:param=val n/a
    Name       ...  name                text                n/a 


EXAMPLES

    With use of configuration file:
        ./ps2.sh -f default.conf input_data_file  

    With use of commandline options:
        ./ps2.sh -n PS2 -Y -5 -y 100  -x "[2009/05/11 15:24:00]" -X "[2009/05/11 07:47:00]" -e type=circles -T 12 -S 1.7 -F 10 -v data/sin_day_part1

EXIT CODES

    0   Success
    1   No params given
    2   Syntax or usage error
    3   Input values not valid
    4   Gnuplot error

VERSION

    This documentation page is current for version 1.0 of main script.

SEE ALSO

    gnuplot, wget, ffmpeg

AUTHOR

    This script was written as semestral work in subject BI-PS2 at FIT CVUT by Jan Sokol. Contact mail is sokolja2@fit.cvut.cz.

