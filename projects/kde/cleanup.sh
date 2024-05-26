#!/bin/sh

# go to prefix
cd ~/projects/kde || exit 1

# kill all old stuff
rm -rf ~/projects/kde/src ~/projects/kde/build ~/projects/kde/usr || exit 1

# get new kde-builder
mkdir -p ~/projects/kde/src || exit 1
git clone https://invent.kde.org/sdk/kde-builder.git ~/projects/kde/src/kde-builder || exit 1

# start from scratch
exec ./src/kde-builder/kde-builder --rc-file=~/projects/kde/kdesrc-buildrc --include-dependencies breeze konsole kate dolphin
