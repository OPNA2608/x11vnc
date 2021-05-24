{ codename
, rev
, isRelease ? false
, sha256
}:

{ stdenv, lib, fetchsvn
, freebasic
, openeuphoria
, scons
, libX11
, libXext
, libXpm
, libXrandr
, libXrender
, ncurses
, SDL2
, SDL2_mixer
, xorgproto
, libxml2
}:

let
  dir = if isRelease then "rel/${codename}" else "wip";
  linkflagDeps = [ ncurses SDL2 SDL2_mixer libX11 libXext libXpm libXrandr libXrender libxml2 ];
in
stdenv.mkDerivation rec {
  pname = "ohrrpgce-${codename}${lib.optionalString (!isRelease) "-unstable"}";
  version = rev;

  src = fetchsvn {
    url = "https://rpg.hamsterrepublic.com/source";
    inherit rev sha256;
  };

  postPatch = ''
    cd ${dir}
    patchShebangs .
    substituteInPlace SConscript \
      --replace "CFLAGS = ['-Wall']" "CFLAGS = ['-Wall','-isystem${xorgproto}/include','-isystem${libX11.dev}/include','-isystem${ncurses.dev}/include']" \
      --replace "CXXLINKFLAGS = []" "CXXLINKFLAGS = ['${lib.strings.concatMapStringsSep "','" (x: "-L" + lib.makeLibraryPath [ x ]) linkflagDeps}']"

    # For test that checks access to file without permissions
    substituteInPlace filetest.bas \
      --replace "/etc/sudoers" "$PWD/unreadable"
    touch unreadable
    chmod a-r unreadable
  '' + lib.optionalString (lib.versionOlder version "12281") ''
    # Work around precompiled OpenEuphoria -ffast-math problem in older revisions
    substituteInPlace SConscript \
      --replace "'install', source = [GAME, CUSTOM, HSPEAK]" "'install', source = [GAME, CUSTOM]"
  '';

  nativeBuildInputs = [ scons freebasic ];

  buildInputs = linkflagDeps ++ [ openeuphoria ];

  preConfigure = ''
    echo 'Revision: ${rev}' > svninfo.txt
  '';

  sconsFlags = [
    "gfx=sdl2+fb"
    "music=sdl2"
    # "release=1" needs nixpkgs-compiled openeuphoria, https://github.com/ohrrpgce/ohrrpgce/issues/1119
    "lto=0"
    "asan=0"
    "profile=0"
    "asm=0"
    "portable=0"
  ];

  enableParallelBuilding = true;

  preBuild = lib.optionalString (lib.versionOlder version "12281") ''
    eubind hspeak.exw
  '';

  buildFlags = [
    "ohrrpgce-game"
    "ohrrpgce-custom"
    "unlump"
    "relump"
    (lib.optionalString (lib.versionAtLeast version "12281") "hspeak")
    "reload2xml"
    "xml2reload"
  ];

  # doCheck = true;
  doCheck = false;

  # checkFlags doesn't work
  checkFlagsArray = [
    "reloadtest"
    "rbtest"
    "vectortest"
    "utiltest"
    "filetest"
    (lib.optionalString (lib.versionAtLeast version "12281") "commontest")
    # "hspeaktest" bad exit code despite passing with all errors marked as known-failures
    # "miditest" expects interactive input, passes but not sure if useful
    # "autotest" needs graphics
    # "interactivetest" needs graphics
  ];

  # Manually run tests that don't get executed by scons targets
  postCheck = ''
    for test in ${toString checkFlagsArray}; do
      echo $test
      ./$test
    done
  '';

  postInstall = ''
    mv $out/{games,bin}
    for extraTool in reload2xml xml2reload; do
      install -m755 $extraTool $out/bin/$extraTool
    done
  '' + lib.optionalString (lib.versionOlder version "12281") ''
    install -m755 hspeak $out/bin/hspeak
  '';
}
