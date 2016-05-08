Desc

NAME

  ps2.sh - Script that creates animation of gnuplot frames from plaintext input files.

SYNOPSIS

  ps2.sh [-v] [-V] [-h] [-l LEGEND] [-f CONFIGFILE] [-T TIME] [-F FPS] [-e EFFECTPARAMS] [-g GNUPLOTPARAMS] [-y YMIN] [-Y YMAX] [-x XMIN] [-X XMAX] [-t TIMEFORMAT] -n name FILE...

DESCRIPTION

Bash script that creates a .mp4 animation from source (sources) of data - URLs or files. Input data in files are in format "Date [ws] float value", eg. "[2009/05/11 07:33:00] 5".     Script depends on gnuplot and ffmpeg. Uses gnuplot for creating each frame in animation and then ffmpeg for combining frames into animation.

OPTIONS

    -v      Verbose mode. Causes script to print messages about its progress. It is helpfull when debuging problems.
    -V      Display the number version and exit.
    -h      Output a short summary of available command line options.
    -l LEGEND        Name of the graph shown in animation.
    -f CONfIGFILE    Uses the directives in the file config on startup.
    -T TIME
    -F FPS
    -e EFFECTPARAMS
    -g GNUPLOTPARAMS
    -y YMIN
    -Y YMAX
    -x XMIN
    -X XMAX
    -t TIMEFORMAT
    -n NAME


EXAMPLES

VERSION
    This documentation page is current for version 1.0 of main script.

SEE ALSO
    gnuplot, wget, ffmpeg

AUTHOR
    This script was written as semestral work in subject BI-PSA at FIT CVUT by Jan Sokol. Contact mail is sokolja2@fit.cvut.cz.

