{ stdenv
, lib
, fetchFromGitHub
}:

stdenv.mkDerivation rec {
  pname = "miniaudio";
  version = "0.10.33";

  src = fetchFromGitHub {
    owner = "mackron";
    repo = "miniaudio";
    # project doesn't use tags for releases
    rev = "fca829edefd8389380f8e3ee26cc4b8c426dd742";
    sha256 = "0250ljhh8695mmxr013bdmxxc61dzl7ks447f9zy0y2g0ivhx2kr";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 miniaudio.h $out/include/miniaudio.h

    runHook postInstall
  '';

  meta = with lib; {
    description = "Single file audio playback and capture library written in C";
    homepage = "https://miniaud.io/";
    license = with licenses; [ publicDomain mit ];
    platforms = platforms.all;
    maintainers = with maintainers; [ OPNA2608 ];
  };
}
