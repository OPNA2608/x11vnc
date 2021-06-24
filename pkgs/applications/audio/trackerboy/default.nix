{ mkDerivation, lib, fetchFromGitHub
, cmake
, qtbase, alsa-lib, libpulseaudio, libjack2
}:

mkDerivation rec {
  pname = "trackerboy";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "stoneface86";
    repo = "trackerboy";
    rev = "v${version}";
    fetchSubmodules = true;
    sha256 = "07vzx7hgzkkr5phg40hnxwav0pvpl5c2fiijf8c6dcnpvc25mrck";
  };

  postPatch = ''
    substituteInPlace ui/forms/ExportWavDialog.cpp \
      --replace 'setDuration((unsigned)mLoopSpin' 'setDuration(mLoopSpin'
    head -n-2 external/gbapu/src/_internal/Mixer.cpp > Mixer.cpp
    echo '
    template void Mixer::mixfast<MixMode::lowQualityLeft>(int8_t delta, uint32_t cycletime);
    template void Mixer::mixfast<MixMode::lowQualityRight>(int8_t delta, uint32_t cycletime);
    template void Mixer::mixfast<MixMode::lowQualityMiddle>(int8_t delta, uint32_t cycletime);
    template void Mixer::mixfast<MixMode::highQualityLeft>(int8_t delta, uint32_t cycletime);
    template void Mixer::mixfast<MixMode::highQualityRight>(int8_t delta, uint32_t cycletime);
    template void Mixer::mixfast<MixMode::highQualityMiddle>(int8_t delta, uint32_t cycletime);
    ' >> Mixer.cpp
    echo "}" >> Mixer.cpp
    mv {,external/gbapu/src/_internal/}Mixer.cpp

    substituteInPlace ui/core/Miniaudio.cpp \
      --replace 'QString::fromLatin1' 'QString::fromUtf8'
  '';

  nativeBuildInputs = [ cmake ];

  buildInputs = [ qtbase alsa-lib libpulseaudio libjack2 ];

  installPhase = ''
    runHook preInstall

    install -Dm755 {ui,$out/bin}/trackerboy

    runHook postInstall
  '';

  preFixup = ''
    qtWrapperArgs+=(--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ alsa-lib libpulseaudio libjack2 ]})
  '';
}
