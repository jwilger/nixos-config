{ lib, pkgs, ... }:
let
  isX86_64Linux = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
in
lib.mkIf isX86_64Linux
{
  programs = {
    steam = {
      enable = true;
      extest.enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };
    gamemode.enable = true;
    appimage = {
      enable = true;
      binfmt = true;
    };
  };
}
