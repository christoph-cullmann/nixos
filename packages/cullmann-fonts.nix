{
  stdenvNoCC,
  lib,
}:
stdenvNoCC.mkDerivation {
  pname = "cullmann-fonts";
  version = "1.0";
  src = /nix/data/nixos/secret/fonts;

  installPhase = ''
    mkdir -p $out/share/fonts/truetype/
    cp -r $src/*.{ttf,otf} $out/share/fonts/truetype/
  '';

  meta = with lib; {
    description = "Cullmann's Fonts";
    homepage = "https://cullmann.io/";
    platforms = platforms.all;
  };
}
