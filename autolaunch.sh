#! /bin/bash
launchdir=$(dirname $(realpath $0))
echo launching purr-data in $launchdir
cd $launchdir

# if purr-data still runs, we need to relaunch it
if xdotool search --name purr-data; then
    killall purr-data
fi

purr-data $launchdir/../raptor7/lac-demo-raptor.pd $launchdir/lac-demo.pd &

# wait for window to map (needs xdotool)
xdotool search --sync --name purr-data

# if Ardour still runs, we need to relaunch it
if xdotool search --name Ardour; then
    killall ArdourGUI
fi

# launch Ardour (we use this as an instrument rack)
# NOTE: This assumes an "algojuggle-rack" session in the ~/Documents/ardour
# folder. You'll have to provide this and adjust the filename accordingly.
ardour8 ~/Documents/ardour/algojuggle-rack/algojuggle-rack.ardour

# NOTE: We'd really like to launch Ardour in the background here, but that
# doesn't appear to work. Instead, we just wait for Ardour to finish and quit.

# if purr-data still runs, force it to exit
if xdotool search --name purr-data; then
    killall purr-data
fi
