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
    catppuccin-cursors.mochaLavender
    papirus
    nwg-look
  ];

  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts.sansSerif = [ "JetBrainsMono Nerd Font" ];

  catppuccin = {
    gtk = {
      enable = false;
    };
  };

  home.pointerCursor = {
    enable = true;
    package = pkgs.catppuccin-cursors.mochaLavender;
    name = "catppuccin-mocha-lavender-cursors";
    size = 48;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
  };
  gtk = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = "mocha";
        accent = "lavender";
      };
    };
    theme = {
      name = "Dracula";
      package = pkgs.dracula-theme;
    };
    cursorTheme = {
      name = "catppuccin-mocha-lavender-cursors";
      package = pkgs.catppuccin-cursors.mochaLavender;
      size = 24;
    };
    # gtk3.extraConfig = {
    #   "gtk-xft-dpi" = "196608";
    #   "Gdk/WindowScalingFactor" = 2;
    # };
    # gtk4.extraConfig = {
    #   "gtk-xft-dpi" = "196608";
    #   "Gdk/WindowScalingFactor" = 2;
    # };
  };
}
