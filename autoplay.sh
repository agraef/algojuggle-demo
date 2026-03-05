#! /bin/bash
launchdir=$(dirname $(realpath $0))
echo launching purr-data in $launchdir
purr-data $launchdir/../raptor7/lac-demo-raptor.pd $launchdir/lac-demo.pd &
sleep 1

