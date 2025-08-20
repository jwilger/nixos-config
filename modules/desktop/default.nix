{ pkgs, username, ... }:
{
  environment.systemPackages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.noto
    twemoji-color-font
    networkmanagerapplet
    adwaita-icon-theme
    vanilla-dmz # DMZ cursor theme
  ];

  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts.sansSerif = [ "JetBrainsMono Nerd Font" ];

  # System-wide cursor theme setting
  environment.etc."X11/Xresources".text = ''
    Xcursor.theme: Vanilla-DMZ
    Xcursor.size: 24
  '';

  # System-level cursor configuration
  environment.etc."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-cursor-theme-name=Vanilla-DMZ
    gtk-cursor-theme-size=24
  '';

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
  services.hypridle.enable = true;

  nix = {
    settings = {
      substituters = [
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
  };

  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";

      # X11 cursor theme config
      displayManager.sessionCommands = ''
        ${pkgs.xorg.xsetroot}/bin/xsetroot -xcf ${pkgs.vanilla-dmz}/share/icons/Vanilla-DMZ/cursors/left_ptr 24
      '';
    };

    libinput = {
      enable = true;
      # mouse = {
      #   accelProfile = "flat";
      # };
    };
  };

  programs._1password.enable = true;
  # Ensure the 1Password CLI binary is installed for the agent
  programs._1password.package = pkgs._1password-cli;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "${username}" ];
  };
}
