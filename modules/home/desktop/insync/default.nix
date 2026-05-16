{ lib, pkgs, ... }:
let
  isX86_64Linux = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
in
lib.mkIf isX86_64Linux
{
  home.packages = with pkgs; [
    insync
  ];
}
