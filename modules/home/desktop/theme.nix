{ pkgs, ... }:
let
  papirus = pkgs.catppuccin-papirus-folders.override {
    flavor = "mocha";
    accent = "lavender";
  };
in
{
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.noto
    twemoji-color-font
    noto-fonts-emoji
    papirus
    nwg-look
    vanilla-dmz
    libsForQt5.qtstyleplugin-kvantum
  ];

  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts.sansSerif = [ "JetBrainsMono Nerd Font" ];

  gtk = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    theme = {
      name = "Dracula";
      package = pkgs.dracula-theme;
    };
    cursorTheme = {
      name = "Vanilla-DMZ";
      package = pkgs.vanilla-dmz;
      size = 24;
    };
  };

  # Qt platform theme for cursor consistency
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style = {
      name = "kvantum";
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 24;
  };

  xresources.properties = {
    "Xcursor.theme" = "Vanilla-DMZ";
    "Xcursor.size" = 24;
  };

  # Additional XDG configuration
  xdg.configFile = {
    # For applications reading standard icons.theme file
    "icons/default/index.theme".text = ''
      [Icon Theme]
      Inherits=Vanilla-DMZ
      Name=Default
      Comment=Default Cursor Theme
    '';

    # Kvantum configuration to respect cursor theme
    "Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=Catppuccin-Mocha
    '';
  };
}
