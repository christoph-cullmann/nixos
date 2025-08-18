#!/bin/sh

# go to prefix
cd ~/projects/kde || exit 1

# kill all old stuff
rm -rf ~/projects/kde/src ~/projects/kde/build ~/projects/kde/usr ~/projects/kde/log || exit 1

# get new kdesrc-build
mkdir -p ~/projects/kde/src || exit 1
git clone https://invent.kde.org/sdk/kdesrc-build.git ~/projects/kde/src/kdesrc-build || exit 1

# start from scratch
exec ./src/kdesrc-build/kdesrc-build --rc-file=~/projects/kde/kdesrc-buildrc --include-dependencies breeze kio-extras konsole kate
