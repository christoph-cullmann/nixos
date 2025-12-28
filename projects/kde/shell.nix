with import <nixpkgs> {};

# dev env
stdenv.mkDerivation {
  name = "nix-shell";
  # ensure the local KDE things are in path
  shellHook = ''
export PATH=~/projects/kde/usr/bin:~/projects/kde:~/projects/kde/src/kdesrc-build:$PATH

# fix Qt tests for rcc
unset QT_RCC_SOURCE_DATE_OVERRIDE
unset SOURCE_DATE_EPOCH

# fix valgrind
export QT_ENABLE_REGEXP_JIT=0

export QT_PLUGIN_PATH=~/projects/kde/usr/lib/plugins:~/projects/kde/usr/lib64/plugins:${pkgs.qt6.qtbase.qtPluginPrefix}:${pkgs.lib.getBin pkgs.qt6.qtsvg}/${pkgs.qt6.qtbase.qtPluginPrefix}:${pkgs.lib.getBin pkgs.qt6.qtwayland}/${pkgs.qt6.qtbase.qtPluginPrefix}:${pkgs.lib.getBin pkgs.qt6.qtspeech}/${pkgs.qt6.qtbase.qtPluginPrefix}:$QT_PLUGIN_PATH
export QML2_IMPORT_PATH=~/projects/kde/usr/lib/qml:$QML2_IMPORT_PATH

export QT_QUICK_CONTROLS_STYLE_PATH=~/projects/kde/usr/lib/qml/QtQuick/Controls.2/:~/projects/kde/usr/lib64/qml/QtQuick/Controls.2/:$QT_QUICK_CONTROLS_STYLE_PATH
  '';

  # add all needed stuff to have a KDE KF6 Qt6 env
  nativeBuildInputs = with pkgs; [
    acl
    angle
    appstream
    attr
    bison
    boost
    bzip2
    chromium
    cmake
    ctags
    curl
    discount
    djvulibre
    docbook_xml_dtd_45
    docbook_xsl_ns
    doxygen
    ebook_tools
    exiv2
    fast-float
    flex
    gdb
    giflib
    gitFull
    gperf
    gpgme
    graphviz
    hunspell
    hunspellDicts.en_US
    intltool
    isocodes
    kdePackages.kimageannotator
    kdePackages.poppler
    kdePackages.wayland-protocols
    lcms2
    libarchive
    libavif
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
    libqalculate
    libraw
    libsecret
    libselinux
    libsndfile
    libspectre
    libtommath
    libva
    libxkbcommon
    libxml2
    libxslt
    libzip
    linux-pam
    lm_sensors
    lmdb
    mesa
    meson
    modemmanager
    llvmPackages.clang-tools # clang
    llvmPackages.libclang.python # git-clang-format
    networkmanager
    ninja
    openal
    openjpeg
    openssl
    pcre
    perl
    perlPackages.IOSocketSSL
    perlPackages.JSONXS
    perlPackages.NetDBus
    perlPackages.URI
    perlPackages.XMLParser
    perlPackages.YAMLPP
    python312
    python312Packages.build
    python312Packages.click
    python312Packages.jinja2
    python312Packages.lxml
    python312Packages.overrides
    python312Packages.promise
    python312Packages.pyaml
    python312Packages.pyside6
    python312Packages.python-gitlab
    python312Packages.setproctitle
    python312Packages.shiboken6
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
    qt6Packages.qgpgme
    sdl3
    simdutf
    skia
    udev
    util-linux
    valgrind
    wayland
    wayland-protocols
    wayland-scanner
    woff2
    xcb-util-cursor
    xdotool
    xercesc
    xml2
    xmlto
    xorg.libSM
    xorg.libX11
    xorg.libXau
    xorg.libxcb
    xorg.libxcvt
    xorg.libXdmcp
    xorg.libXext
    xorg.libXfixes
    xorg.libXft
    xorg.xcbutil
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.xcbutilwm
    zlib
    zstd
    xz
  ];
}
