{ stdenv, fetchFromGitHub
, autoreconfHook, gnome3, intltool, automake, pkg-config
, glib
}:

stdenv.mkDerivation rec {
  pname = "gsettings-ubuntu-touch-schemas-unstable";
  version = "2018-10-06";

  src = fetchFromGitHub {
    owner = "ubports";
    repo = "gsettings-ubuntu-touch-schemas";
    rev = "b3bdf178e4226c91c567b84f1adf9202b2492ca2";
    sha256 = "00zgikp2fyw3izj195yxczrvc3qxlhshjx2ba8v6mq1q7rg15bp1";
  };

  postPatch = ''
    # autoreconf fails otherwise?
    mkdir m4
  '';

  nativeBuildInputs = [ autoreconfHook gnome3.gnome-common intltool automake pkg-config ];

  buildInputs = [ glib ];
}
