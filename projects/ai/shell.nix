with import <nixpkgs> {};

# dev env
stdenv.mkDerivation {
  name = "nix-shell";
  # ensure the local things are in path
  shellHook = ''
export PATH=~/projects/ai/usr/bin:~/projects/ai:$PATH
  '';

  # add all needed stuff to have local ai things
  nativeBuildInputs = with pkgs; [
    appimage-run
  ];
}
