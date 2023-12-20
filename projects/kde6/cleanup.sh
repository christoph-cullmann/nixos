#!/bin/sh

# kill all old stuff
rm -rf ~/projects/kde6/src ~/projects/kde6/build ~/projects/kde6/usr || exit 1

# get new kdesrc-build
mkdir -p ~/projects/kde6/src || exit 1
cd ~/projects/kde6/src || exit 1
git clone https://invent.kde.org/sdk/kdesrc-build.git || exit 1

# start from scratch
exec ./kdesrc-build/kdesrc-build --rc-file=../kdesrc-buildrc --include-dependencies breeze plasma-integration kwayland-integration konsole kate
