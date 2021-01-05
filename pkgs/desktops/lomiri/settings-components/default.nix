{ mkDerivation, lib, fetchFromGitHub
, cmake, cmake-extras
, qtbase, qtquickcontrols2
}:

mkDerivation rec {
  pname = "settings-components-unstable";
  version = "2018-06-10";

  src = fetchFromGitHub {
    owner = "ubports";
    repo = "settings-components";
    rev = "d66cac294e48d2a65ff8b5140187916c0eb1f2e8";
    sha256 = "11hn5vrkiqisyh8flby0hjav4164kj0jrrr2bb99d473spjrv0ds";
  };

  nativeBuildInputs = [ cmake cmake-extras ];

  buildInputs = [ qtbase qtquickcontrols2 ];

  meta = with lib; {
    description = "Ubuntu settings components for Unity8";
    homepage = "https://launchpad.net/ubuntu-settings-components";
    license = with licenses; [ gpl3Only lgpl3Only ];
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = platforms.linux;
  };
}
