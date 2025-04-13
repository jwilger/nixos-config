{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.noto
    twemoji-color-font
    noto-fonts-emoji
    numix-icon-theme-circle
    colloid-icon-theme
    catppuccin
  ];

  catppuccin = {
    enable = true;
    nvim.enable = false;
    flavor = "mocha";
    accent = "lavender";
  };

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    hyprcursor.enable = true;
    name = "Catppuccin-Mocha-Lavender";
    package = pkgs.catppuccin-cursors.mochaLavender;
  };

  nixpkgs.config.packageOverrides = pkgs: {
    colloid-icon-theme = pkgs.colloid-icon-theme.overrice { colorVariants = ["lavender"];};
    catppuccin-gtk = pkgs.catppuccin-gtk.override {
      accents = ["lavender"];
      size = "standard";
      variant = "mocha";
    };
  };

  gtk = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    iconTheme = {
      name = "Colloid";
      package = pkgs.colloid-icon-theme;
    };
  };
}
