{ lib, stdenv, fetchFromGitHub
, cmake, pkg-config, stb, miniaudio
, glfw, glew, kissfft
, alsaLib, fontconfig, libX11
}:

stdenv.mkDerivation rec {
  pname = "bonzomatic";
  version = "2021-03-07";

  src = fetchFromGitHub {
    owner = "Gargaj";
    repo = pname;
    rev = version;
    sha256 = "0gbh7kj7irq2hyvlzjgbs9fcns9kamz7g5p6msv12iw75z9yi330";
  };

  postPatch = ''
    # CMakeFiles/bonzomatic.dir/src/platform_common/FFT.cpp.o: undefined reference to symbol 'dlclose@@GLIBC_2.2.5'
    # libdl.so.2: error adding symbols: DSO missing from command line
    substituteInPlace CMakeLists.txt \
      --replace "PLATFORM_LIBS GL asound fontconfig" "PLATFORM_LIBS GL asound fontconfig dl"
  '';

  nativeBuildInputs = [ cmake pkg-config stb miniaudio ];

  buildInputs = [ glfw glew kissfft ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ alsaLib fontconfig libX11 ];

  cmakeFlags = [
    "-DBONZOMATIC_USE_SYSTEM_GLFW=ON"
    "-DBONZOMATIC_USE_SYSTEM_GLEW=ON"
    "-DBONZOMATIC_USE_SYSTEM_STB=ON"
    "-DBONZOMATIC_USE_SYSTEM_MINIAUDIO=ON"
    "-DBONZOMATIC_USE_SYSTEM_KISSFFT=ON"
  ];

  meta = with lib; {
    description = "Live shader coding tool and Shader Showdown workhorse";
    homepage = "https://github.com/gargaj/bonzomatic";
    license = licenses.unlicense;
    maintainers = with maintainers; [ ilian ];
    platforms = platforms.mesaPlatforms;
  };
}
