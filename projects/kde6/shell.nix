with import <nixpkgs> {};

# use new clang
let myllvm = llvmPackages_16; in

# clang based dev env
myllvm.stdenv.mkDerivation {
  name = "clang-nix-shell";
  # ensure the local KDE things are in path
  shellHook = ''
export PATH=/home/cullmann/projects/kde6/usr/bin:/home/cullmann/projects/kde6:/home/cullmann/projects/kde6/src/kdesrc-build:$PATH

# LD_LIBRARY_PATH only needed if you are building without rpath
# export LD_LIBRARY_PATH=/home/cullmann/projects/kde6/usr/lib:$LD_LIBRARY_PATH

export QT_PLUGIN_PATH=/home/cullmann/projects/kde6/usr/lib/plugins:${pkgs.qt6.qtbase.qtPluginPrefix}:${pkgs.lib.getBin pkgs.qt6.qtsvg}/${pkgs.qt6.qtbase.qtPluginPrefix}:${pkgs.lib.getBin pkgs.qt6.qtwayland}/${pkgs.qt6.qtbase.qtPluginPrefix}:${pkgs.lib.getBin pkgs.qt6.qtspeech}/${pkgs.qt6.qtbase.qtPluginPrefix}:$QT_PLUGIN_PATH
export QML2_IMPORT_PATH=/home/cullmann/projects/kde6/usr/lib/qml:$QML2_IMPORT_PATH

export QT_QUICK_CONTROLS_STYLE_PATH=/home/cullmann/projects/kde6/usr/lib/qml/QtQuick/Controls.2/:$QT_QUICK_CONTROLS_STYLE_PATH
  '';

  # add all needed stuff to have a KDE KF6 Qt6 env
  nativeBuildInputs = with pkgs; [
    acl
    appstream
    attr
    bison
    boost
    bzip2
    cmake
    ctags
    curl
    docbook_xml_dtd_45
    docbook_xsl_ns
    exiv2
    flex
    gdb
    giflib
    gitFull
    gperf
    gpgme
    hunspell
    hunspellDicts.en_US
    intltool
    isocodes
    lcms2
    libcanberra
    libcap
    libdisplay-info
    libepoxy
    libgcrypt
    libGL
    libical
    libinput
    libjpeg
    libjxl
    libnl
    libpcap
    libpng
    libraw
    libselinux
    libsndfile
    libva
    libxkbcommon
    libxml2
    libxslt
    linux-pam
    lm_sensors
    lmdb
    mesa
    meson
    myllvm.libclang.python # git-clang-format
    networkmanager
    ninja
    openal
    openjpeg
    openssl
    pcre
    perl
    perlPackages.IOSocketSSL
    perlPackages.NetDBus
    perlPackages.URI
    perlPackages.XMLParser
    perlPackages.YAMLSyck
    python3Full
    python311Packages.pyaml
    python311Packages.python-gitlab
    pkg-config
    polkit
    qrencode
    qt6.qt3d
    qt6.qt5compat
    qt6.qtbase
    qt6.qtcharts
    qt6.qtconnectivity
    qt6.qtdatavis3d
    qt6.qtdeclarative
    qt6.qtdoc
    qt6.qtimageformats
    qt6.qtlanguageserver
    qt6.qtlottie
    qt6.qtmultimedia
    qt6.qtnetworkauth
    qt6.qtpositioning
    qt6.qtquick3d
    qt6.qtquicktimeline
    qt6.qtremoteobjects
    qt6.qtscxml
    qt6.qtsensors
    qt6.qtserialbus
    qt6.qtserialport
    qt6.qtshadertools
    qt6.qtspeech
    qt6.qtsvg
    qt6.qttools
    qt6.qttranslations
    qt6.qtvirtualkeyboard
    qt6.qtwayland
    qt6.qtwebchannel
    qt6.qtwebengine
    qt6.qtwebsockets
    qt6.qtwebview
    udev
    util-linux
    valgrind
    wayland
    wayland-protocols
    xcb-util-cursor
    xercesc
    xml2
    xorg.libSM
    xorg.libX11
    xorg.libXau
    xorg.libxcb
    xorg.libxcvt
    xorg.libXdmcp
    xorg.libXext
    xorg.libXfixes
    xorg.xcbutil
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.xcbutilwm
    zlib
    zstd
    xz
  ];
}
