{ pkgs, username, ... }:
{
  environment.systemPackages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.noto
    twemoji-color-font
    catppuccin-cursors.mochaLavender
  ];

  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts.sansSerif = ["JetBrainsMono Nerd Font"];

  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "lavender";
  };
  
  programs.hyprland.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
  };
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${pkgs.hyprland}/bin/hyprland";
        user = "${username}";
      };
      default_session = initial_session;
    };
  };
}
