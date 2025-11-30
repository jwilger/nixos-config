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
    displayManager.cosmic-greeter.enable = true;
    desktopManager.cosmic.enable = true;
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

  environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;

  programs.firefox.preferences = {
    "widget.gtk.libadwaita-colors.enabled" = false;
  };

  programs._1password.enable = true;
  # Ensure the 1Password CLI binary is installed for the agent
  programs._1password.package = pkgs._1password-cli;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "${username}" ];
  };

  imports = [
    (import ./gaming.nix { inherit pkgs; })
  ];
}
