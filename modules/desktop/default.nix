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
    displayManager.cosmic-greeter.enable = true;
    desktopManager.cosmic.enable = true;
  };

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
}
