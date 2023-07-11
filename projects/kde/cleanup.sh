#!/bin/sh

# kill all old stuff
rm -rf ~/projects/kde/src ~/projects/kde/build ~/projects/kde/usr || exit 1

# get new kdesrc-build
mkdir -p ~/projects/kde/src || exit 1
cd ~/projects/kde/src || exit 1
git clone git@invent.kde.org:sdk/kdesrc-build.git || exit 1

# start from scratch
exec ./kdesrc-build/kdesrc-build --rc-file=../kdesrc-buildrc --refresh-build --include-dependencies kate konsole
