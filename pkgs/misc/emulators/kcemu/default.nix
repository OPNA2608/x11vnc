{ stdenv, lib, fetchurl, fetchFromGitHub
, autoreconfHook, cmake, pkgconfig, imagemagick, netpbm, perl
, gtk2, ncurses, SDL, xorg, zlib

, enableFastRoughMode ? false
, enableTapeAudio ? true
, libsndfile, audiofile, lame, libvorbis
, enableVideoCapture ? true
, giflib, libtheora, schroedinger, xvidcore
, enableVNC ? true
, libvncserver
}:

let
  z80ex = stdenv.mkDerivation rec {
    pname = "z80ex";
    version = "1.1.21";

    src = fetchurl {
      url = "mirror://sourceforge/${pname}/${pname}/${version}/${pname}-${version}.tar.gz";
      sha256 = "0c15dj2pi47b7xa65j98xicc46svwi5av001w50lnqca0qfm4pkg";
    };

    nativeBuildInputs = [ cmake ];

    cmakeFlags = [
      "-DOPSTEP_FAST_AND_ROUGH=${if enableFastRoughMode then "1" else "0"}"
    ];

    meta = with lib; {
      homepage = "https://sourceforge.net/projects/z80ex/";
      description = "The portable ZiLOG Z80 CPU emulator designed as a library. Goals include : precise opcode emulation (documented & undocumented), exact timings for each opcode (including I/O operations), multiple CPU contexts. disassembler is also included.";
      platform = platforms.all;
      license = licenses.gpl2;
    };
  };

in stdenv.mkDerivation rec {
  pname = "kcemu";
  version = "0.5.2";

  src = fetchFromGitHub {
    owner = "t-paul";
    repo = "kcemu";
    rev = "v${version}";
    sha256 = "0f51gxspfyrhwqf05gk2944p24fd62ci36c26bzg219vcc91vdib";
  };

  enableParallelBuilding = true;

  configureFlags = [
    # Fails to compile
    "--disable-libavformat"
    # https://sourceforge.net/projects/dirac/
    "--disable-libdirac"
    # 1.0.x version of FLAC required
    # 1.3.x currently packaged
    "--disable-libflac"
  ];

  patches = [
    ./0001-remove-custom-epoch-check.patch
    ./0002-fix-gtk2-cflags.patch
  ];

  nativeBuildInputs = [
    autoreconfHook pkgconfig imagemagick netpbm perl
  ];

  buildInputs = [
    ncurses gtk2 SDL xorg.libXmu z80ex zlib
  ]
  ++ lib.optionals enableTapeAudio [
    libsndfile audiofile lame libvorbis
  ]
  ++ lib.optionals enableVideoCapture [
    giflib libtheora schroedinger xvidcore
  ]
  ++ lib.optionals enableVNC [ libvncserver ];

  meta = with lib; {
    homepage = "http://kcemu.sourceforge.net/";
    description = "An emulator for the KC85 homecomputer series and other Z80 based microcomputers like Z1013, LC80, Polycomputer 880 and BIC A5105. The emulation supports a number of additional hardware, e.g. floppy disk drives and extended graphic modules.";
    platform = platforms.linux;
    license = licenses.gpl2Plus;
  };
}
