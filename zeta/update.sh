#!/usr/bin/env zsh

rm -rf nixos-apple-silicon
git clone https://github.com/nix-community/nixos-apple-silicon.git

rm -rf apple-silicon-support
mv nixos-apple-silicon/apple-silicon-support .
git add apple-silicon-support

rm -rf nixos-apple-silicon
