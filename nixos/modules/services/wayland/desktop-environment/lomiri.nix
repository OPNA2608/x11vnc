{ config, lib, pkg, ... }:

with lib;

let
  cfg = config.services.wayland.desktopManager.lomiri;
in
  {
    meta = {
      maintainers = with maintainers; [ OPNA2608 ];
    };

    options = {
      services.wayland.desktopManager.lomiri = {
        enable = mkEnableOption "the Lomiri Desktop Environment";
      };
    };

    config = mkIf cfg.enable {
      environment.systemPackages = (with pkgs.lomiri; [
        unity8
      ]) ++ (with pkgs; [
        mir_1
      ]);
    };
  }
