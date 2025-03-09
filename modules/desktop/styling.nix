# Stylix theming configuration
{ pkgs, ... }:

{
  stylix = {
    enable = true;
    image = ./../../wallpaper.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
    polarity = "dark";
  };
}