{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  # ensure this KDE things are in path
  shellHook = ''
    export PATH=/home/cullmann/projects/kde/build/kate/bin:/home/cullmann/projects/kde:/home/cullmann/projects/kde/src/kdesrc-build:/home/cullmann/projects/kde/usr/bin:$PATH
  '';

  # add all needed stuff to have a KDE KF5 Qt5 env
  nativeBuildInputs = with pkgs; [
    acl
    appstream
    attr
    bison
    boost
    bzip2
    clang-tools
    cmake
    docbook_xml_dtd_45
    docbook_xsl_ns
    flex
    gdb
    giflib
    gitFull
    gperf
    gpgme
    intltool
    isocodes
    lcms2
    libcanberra
    libcap
    libclang.python
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
    libselinux
    libsForQt5.accounts-qt
    libsForQt5.breeze-icons
    libsForQt5.qca-qt5
    libsForQt5.qtspeech
    libsForQt5.signond
    libsndfile
    libxkbcommon
    libxml2
    libxslt
    linux-pam
    lm_sensors
    lmdb
    mesa
    meson
    networkmanager
    ninja
    openal
    openssl
    pcre
    perl
    perlPackages.IOSocketSSL
    perlPackages.NetDBus
    perlPackages.URI
    perlPackages.XMLParser
    perlPackages.YAMLSyck
    python3Full
    pkg-config
    polkit
    qrencode
    qt5.qt3d
    qt5.qtbase
    qt5.qtcharts
    qt5.qtconnectivity
    qt5.qtdeclarative
    qt5.qtdoc
    qt5.qtimageformats
    qt5.qtlottie
    qt5.qtmultimedia
    qt5.qtnetworkauth
    qt5.qtquickcontrols
    qt5.qtquickcontrols2
    qt5.qtscxml
    qt5.qtsensors
    qt5.qtserialbus
    qt5.qtserialport
    qt5.qtsvg
    qt5.qttools
    qt5.qttranslations
    qt5.qtvirtualkeyboard
    qt5.qtwayland
    qt5.qtwebchannel
    qt5.qtwebengine
    qt5.qtwebsockets
    qt5.qtwebview
    qt5.qtx11extras
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