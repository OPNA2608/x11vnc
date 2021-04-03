{ pname
, projName
, version
, src
, withGTK3 ? true
, withOfficialBranding ? false
, enableParallelBuilding ? false
, config
, meta
, updateScript ? null
, postPatch ? ""
, extraInstallPhase ? ""
, extraBuildInputs ? []
}:

{ stdenv, lib, desktop-file-utils, writeText
, pkg-config, autoconf213, alsaLib, bzip2, cairo
, dbus, dbus-glib, ffmpeg, file, fontconfig, freetype
, gnome2, gnum4, gtk2, gtk3, hunspell, libevent, libjpeg
, libnotify, libstartup_notification, wrapGAppsHook
, libGLU, libGL, perl, python2, libpulseaudio
, unzip, libX11, libXext, libXft, libXi, libXrender
, libXScrnSaver, libXt, pixman, xorgproto, wget
, which, yasm, zip, zlib
}:

stdenv.mkDerivation rec {
  inherit pname version src meta;

  nativeBuildInputs = [
    desktop-file-utils file gnum4 perl pkg-config python2 wget which wrapGAppsHook unzip
  ];

  buildInputs = [
    alsaLib bzip2 cairo dbus dbus-glib ffmpeg fontconfig freetype
    gnome2.GConf gtk2 hunspell libevent libjpeg libnotify
    libstartup_notification libGLU libGL libpulseaudio libX11
    libXext libXft libXi libXrender libXScrnSaver libXt pixman
    xorgproto yasm zip zlib
  ]
  ++ lib.optional withGTK3 gtk3
  ++ extraBuildInputs;

  enableParallelBuilding = true;

  mozconfig = writeText "${pname}-${version}.mozconfig" ''
    # Clear this if not a 64bit build
    _BUILD_64=${lib.optionalString stdenv.hostPlatform.is64bit "1"}

    # Set GTK Version to 2 or 3
    _GTK_VERSION=${if withGTK3 then "3" else "2"}

    ${config}

    #
    # NixOS-specific adjustments
    #

    ac_add_options --x-libraries=${lib.makeLibraryPath [ libX11 ]}

    ac_add_options --prefix=$out

    mk_add_options MOZ_MAKE_FLAGS="-j${if enableParallelBuilding then "$NIX_BUILD_CORES" else "1"}"
    mk_add_options AUTOCONF=${autoconf213}/bin/autoconf
  '';

  inherit postPatch;

  configurePhase = ''
    runHook preConfigure

    export MOZ_NOSPAM=1
    ln -s ${mozconfig} mozconfig

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    ./mach build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    ./mach install

    ${extraInstallPhase}

    # Remove SDK cruft. FIXME: move to a separate output?
    rm -r $out/{share/idl,include,lib/${pname}-devel-${version}}

    runHook postInstall
  '';

  dontWrapGApps = true;

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ ffmpeg libpulseaudio ]}"
    )
    for binName in ${pname}{,-bin}; do
      wrapGApp $out/lib/${pname}-${version}/$binName
    done

    # install places symlink with projName in bin
    # let's manually make a symlink with pname instead so there's no nameclash potential
    rm $out/bin/${pname}
    ln -s $out/lib/${pname}-${version}/${pname} $out/bin/${pname}
  '';

  passthru = {
    inherit updateScript;
  };
}
