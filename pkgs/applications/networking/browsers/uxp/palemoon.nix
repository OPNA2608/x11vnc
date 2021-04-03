{ callPackage, stdenv, lib, fetchFromGitHub, writeScript
, withGTK3 ? true
, libX11, autoconf213
, libjpeg, zlib, bzip2, pixman
}:

let
  uxpBuild = opts: callPackage (import ./common.nix opts) { };
  projName = "palemoon";
  version = "29.1.0";
  src = fetchFromGitHub {
    githubBase = "repo.palemoon.org";
    owner = "MoonchildProductions";
    repo = "Pale-Moon";
    rev = "${version}_Release";
    fetchSubmodules = true;
    sha256 = "02blhk3v7gpnicd7s5l5fpqvdvj2279g3rq8xyhcd4sw6qnms8m6";
  };
  updatePalemoon = pname: writeScript "update-${pname}" ''
    #!/usr/bin/env nix-shell
    #!nix-shell -i bash -p common-updater-scripts curl libxml2

    set -eu -o pipefail

    # Only release note announcement == finalized release
    version="$(
      curl -s 'http://www.palemoon.org/releasenotes.shtml' |
      xmllint --html --xpath 'html/body/table/tbody/tr/td/h3/text()' - 2>/dev/null | head -n1 |
      sed 's/v\(\S*\).*/\1/'
    )"
    update-source-version ${pname} "$version"
  '';
in

{
  palemoon = uxpBuild rec {
    pname = "palemoon";

    inherit projName version src withGTK3;

    updateScript = updatePalemoon pname;

    withOfficialBranding = true;

    # Keep this close to the official .mozconfig file. (_BUILD_64, _GTK_VERSION, X11 libs & other shared things are added by common.nix)
    # Only minor changes for portability are permitted with branding enabled.
    # https://developer.palemoon.org/build/linux/
    config = ''
      # Standard build options for Pale Moon
      ac_add_options --enable-application=palemoon
      ac_add_options --enable-optimize="-O2 -w"
      ac_add_options --enable-default-toolkit=cairo-gtk$_GTK_VERSION
      ac_add_options --enable-jemalloc
      ac_add_options --enable-strip
      ac_add_options --enable-devtools
      ac_add_options --disable-eme
      ac_add_options --disable-webrtc
      ac_add_options --disable-gamepad
      ac_add_options --disable-tests
      ac_add_options --disable-debug
      ac_add_options --disable-necko-wifi
      ac_add_options --disable-updater
      ac_add_options --with-pthreads

      # Please see https://www.palemoon.org/redist.shtml for restrictions when using the official branding.
      ac_add_options --enable-official-branding
      export MOZILLA_OFFICIAL=1

      # For versions after 28.12.0
      ac_add_options --enable-phoenix-extensions

      export MOZ_PKG_SPECIAL=gtk$_GTK_VERSION
    '';

    extraInstallPhase = ''
      # Fix missing icon due to wrong WMClass
      substituteInPlace ./palemoon/branding/official/palemoon.desktop \
        --replace 'StartupWMClass="pale moon"' 'StartupWMClass=Pale moon'

      desktop-file-install --dir=$out/share/applications \
        ./palemoon/branding/official/palemoon.desktop

      # TODO move to common.nix (how?)
      for iconname in default{16,22,24,32,48,256} mozicon128; do
        n=''${iconname//[^0-9]/}
        size=$n"x"$n
        install -Dm644 ./palemoon/branding/official/$iconname.png $out/share/icons/hicolor/$size/apps/palemoon.png
      done
    '';

    meta = with lib; {
      description = "An Open Source, Goanna-based web browser focusing on efficiency and customization";
      longDescription = ''
        Pale Moon is an Open Source, Goanna-based web browser focusing on
        efficiency and customization.

        Pale Moon offers you a browsing experience in a browser completely built
        from its own, independently developed source that has been forked off from
        Firefox/Mozilla code a number of years ago, with carefully selected
        features and optimizations to improve the browser's stability and user
        experience, while offering full customization and a growing collection of
        extensions and themes to make the browser truly your own.
      '';
      homepage = "https://www.palemoon.org/";
      license     = [ licenses.mpl20 "https://www.palemoon.org/redist.shtml" ];
      maintainers = with maintainers; [ AndersonTorres OPNA2608 ];
      platforms   = [ "i686-linux" "x86_64-linux" ];
    };
  };

  newmoon = uxpBuild rec {
    pname = "newmoon";

    inherit projName version src withGTK3;

    updateScript = updatePalemoon pname;

    withOfficialBranding = false;

    enableParallelBuilding = true;

    extraBuildInputs = [ libjpeg zlib bzip2 pixman ];

    config = ''
      # Standard build options for Pale Moon
      ac_add_options --enable-application=palemoon
      ac_add_options --enable-optimize="-O2 -w"
      ac_add_options --enable-default-toolkit=cairo-gtk$_GTK_VERSION
      ac_add_options --enable-jemalloc
      ac_add_options --enable-strip
      ac_add_options --enable-devtools
      ac_add_options --disable-eme
      ac_add_options --disable-webrtc
      ac_add_options --disable-gamepad
      ac_add_options --disable-tests
      ac_add_options --disable-debug
      ac_add_options --disable-necko-wifi
      ac_add_options --disable-updater
      ac_add_options --with-pthreads

      # Branding
      ac_add_options --with-distribution-id=org.nixos

      # System libraries
      ac_add_options --with-system-jpeg
      ac_add_options --with-system-zlib
      ac_add_options --with-system-bz2
      ac_add_options --with-system-ffi
      ac_add_options --with-system-pixman
      ac_add_options --enable-system-cairo

      # For versions after 28.12.0
      ac_add_options --enable-phoenix-extensions

      ac_add_options --x-libraries=${lib.makeLibraryPath [ libX11 ]}

      export MOZ_PKG_SPECIAL=gtk$_GTK_VERSION
    '';

    postPatch = ''
      # Rename browser
      substituteInPlace ${projName}/app/application.ini \
        --replace "Pale Moon" "New Moon"
      substituteInPlace ${projName}/confvars.sh \
        --replace "Palemoon" "Newmoon"
      # Unbranded desktop file is missing alot of translations
      cp ${projName}/branding/{official/palemoon,unofficial/newmoon}.desktop
      substituteInPlace ${projName}/branding/unofficial/newmoon.desktop \
        --replace "Pale Moon" "New Moon" \
        --replace "palemoon" "newmoon"
    '';

    extraInstallPhase = ''
      # Set custom distributor details
      mkdir $out/lib/${pname}-${version}/distribution
      cat >$out/lib/${pname}-${version}/distribution/distribution.ini <<EOF
      [Global]
      id=nixos
      version=1.0
      about=New Moon for Nixpkgs

      [Preferences]
      app.distributor=nixos
      app.distributor.channel=newmoon
      app.partner.nixos=nixos
      EOF

      desktop-file-install --dir=$out/share/applications \
        ./palemoon/branding/unofficial/newmoon.desktop

      # TODO move to common.nix (how?)
      for iconname in default{16,32,48} mozicon128; do
        n=''${iconname//[^0-9]/}
        size=$n"x"$n
        install -Dm644 ./palemoon/branding/unofficial/$iconname.png $out/share/icons/hicolor/$size/apps/${pname}.png
      done
    '';

    meta = with lib; {
      description = "An Open Source, Goanna-based web browser focusing on efficiency and customization";
      longDescription = ''
        New Moon is an Open Source, Goanna-based web browser focusing on
        efficiency and customization. It's a debranded build of Pale Moon.

        New Moon offers you a browsing experience in a browser completely built
        from its own, independently developed source that has been forked off from
        Firefox/Mozilla code a number of years ago, with carefully selected
        features and optimizations to improve the browser's stability and user
        experience, while offering full customization and a growing collection of
        extensions and themes to make the browser truly your own.
      '';
      homepage = "https://www.palemoon.org/";
      license     = [ licenses.mpl20 ];
      maintainers = with maintainers; [ OPNA2608 ];
      platforms   = platforms.linux;
    };
  };
}
