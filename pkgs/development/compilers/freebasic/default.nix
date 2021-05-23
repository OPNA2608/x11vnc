{ stdenv, lib, fetchzip
, ncurses5, ncurses, gpm, libX11, libXpm, libXext, libXrandr, libffi, libGL
}:

stdenv.mkDerivation rec {
  pname = "freebasic";
  version = "1.07.3";

  src = fetchzip {
    url = "mirror://sourceforge/fbc/FreeBASIC-${version}-source-bootstrap.tar.xz";
    sha256 = "1g4h6hzjxccj9zivaac97is096pf3bylma0yh6qndxi8iw0hv1da";
  };

  buildInputs = [ ncurses gpm libX11 libXpm libXext libXrandr libffi libGL ];

  enableParallelBuilding = true;

  hardeningDisable = [ "format" ];

  dontConfigure = true;

  makeFlags = [ "prefix=${placeholder "out"}" ];

  preBuild = ''
    make bootstrap ${lib.optionalString enableParallelBuilding "-j$NIX_BUILD_CORES -l$NIX_BUILD_CORES"}
    buildFlagsArray+=("FBC=$PWD/bin/fbc -i $PWD/inc")
  '';

  doCheck = true;

  preCheck = ''
    patchShebangs tests
    substituteInPlace makefile \
      --replace 'tests && make' 'tests && $(MAKE)'
  '';

  checkFlags = [ "ENABLE_CONSOLE_OUTPUT=1" ];

  # unit-tests build but executable never exits?
  checkTarget = "log-tests warning-tests";
}
