{ pkgs, ... }:
{
  home.packages = with pkgs; [
    insync
  ];
}
