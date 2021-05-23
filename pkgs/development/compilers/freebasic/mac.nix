{ stdenvNoCC, lib, fetchFromGitHub, fetchzip, llvmPackages }:

# let
#   freebasic-bin = stdenvNoCC.mkDerivation rec {
  stdenvNoCC.mkDerivation rec {
    pname = "freebasic-bin";
    version = "1.06-darwin-wip20160505";

    src = fetchzip {
      url = "http://tmc.castleparadox.com/temp/fbc-${version}.tar.bz2";
      sha256 = "18py71rh2njwr1jvvzxk68fhj6mw9irq0qf8s0glprr4952x4gc4";
    };

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -R * $out

      runHook postInstall
    '';
#   };
# in
# llvmPackages.stdenv.mkDerivation rec {
#   pname = "freebasic";
#   version = "unstable-2019-07-30";
#
#   src = fetchFromGitHub {
#     owner = "rversteegen";
#     repo = "fbc";
#     rev = "7b505526f5b56c3c8061e1b4a476a0c100400360";
#     sha256 = "0nxq6ag21kvs8qrpr4c6cg0xgmh9wq5yn160a9b6mran6i314hxd";
#   };
#
#   nativeBuildInputs = [ freebasic-bin ];
#
#   buildInputs = [ llvmPackages.llvm ];
#
#   hardeningDisable = [ "format" ];
#
#   dontConfigure = true;
#
#   makeFlags = [ "prefix=${placeholder "out"}" ];
#
#   preBuild = ''
#    buildFlagsArray+=("FBC=fbc -gen llvm")
#   '';
#
#   doCheck = true;
#
#   preCheck = ''
#     patchShebangs tests
#     substituteInPlace makefile \
#       --replace 'tests && make' 'tests && $(MAKE)'
#   '';
#
#   checkFlags = [ "ENABLE_CONSOLE_OUTPUT=1" ];
#
#   # unit-tests build but executable never exits?
#   checkTarget = "log-tests warning-tests";
}
