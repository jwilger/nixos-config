{ pkgs, ... }:
let
  papirus = pkgs.catppuccin-papirus-folders.override {
    flavor = "mocha";
    accent = "lavender";
  };
in
{
  home.packages = with pkgs; [
    hyprcursor
    nerd-fonts.jetbrains-mono
    nerd-fonts.noto
    twemoji-color-font
    noto-fonts-emoji
    catppuccin
    catppuccin-cursors.mochaLavender
    papirus
    nwg-look
  ];

  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts.sansSerif = ["JetBrainsMono Nerd Font"];
  
  catppuccin = {
    enable = true;
    nvim.enable = false;
    flavor = "mocha";
    accent = "lavender";
    gtk = {
      enable = true;
      size = "standard";
      tweaks = [ "normal" ];
      flavor = "mocha";
      accent = "lavender";
    };
  };

  gtk.enable = true;

  home.pointerCursor = {
    enable = true;
    package = pkgs.catppuccin-cursors.mochaLavender;
    name = "catppuccin-mocha-lavender-cursors";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
  };
}
