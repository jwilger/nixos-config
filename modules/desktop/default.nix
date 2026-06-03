{ lib
, pkgs
, username
, ...
}:
let
  isX86_64Linux = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
in
{
  environment.systemPackages =
    with pkgs;
    [
      nerd-fonts.jetbrains-mono
      nerd-fonts.noto
      twemoji-color-font
      networkmanagerapplet
      adwaita-icon-theme
      vanilla-dmz # DMZ cursor theme
    ]
    ++ lib.optionals isX86_64Linux [
      google-chrome
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

  services = {
    interception-tools = {
      enable = true;
      plugins = [ pkgs.interception-tools-plugins.dual-function-keys ];
      udevmonConfig = ''
        - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools-plugins.dual-function-keys}/bin/dual-function-keys -c /etc/dual-function-keys.yaml | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
          DEVICE:
            EVENTS:
              EV_KEY: [KEY_CAPSLOCK, KEY_RIGHTSHIFT, KEY_LEFTSHIFT]
      '';
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  # For interception-tools config
  environment.etc."dual-function-keys.yaml".text = ''
    TIMING:
      TAP_MILLISEC: 200
      DOUBLE_TAP_MILLISEC: 0

    MAPPINGS:
      - KEY: KEY_LEFTSHIFT
        TAP: [KEY_LEFTSHIFT, KEY_9]
        HOLD: KEY_LEFTSHIFT
      - KEY: KEY_RIGHTSHIFT
        TAP: [KEY_RIGHTSHIFT, KEY_0]
        HOLD: KEY_RIGHTSHIFT
      - KEY: KEY_CAPSLOCK
        TAP: KEY_ESC
        HOLD: KEY_LEFTCTRL
  '';

  programs._1password = lib.mkIf isX86_64Linux {
    enable = true;
    package = pkgs._1password-cli;
  };
  programs._1password-gui = lib.mkIf isX86_64Linux {
    enable = true;
    polkitPolicyOwners = [ "${username}" ];
  };

  imports = [
    (import ./gaming.nix)
    (import ./niri.nix)
  ];
}
