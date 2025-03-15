# System-wide 1Password configuration
{ config, pkgs, ... }:

{
  # Enable 1Password in system configuration
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Ensure browser integration is enabled
    polkitPolicyOwners = [ "jwilger" ];
  };

  # System-wide Firefox configuration
  programs.firefox = {
    enable = true;
    preferences = {
      "security.webauth.u2f" = true;
      "security.webauth.webauthn" = true;
      "security.webauth.webauthn.enabled" = true;
      "security.webauth.webauthn_enable_usbtoken" = true;
    };
  };

  # Ensure proper permissions for native messaging
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "com.1password.1password.browser.helper" &&
          subject.local && subject.active && subject.isInGroup("users")) {
        return polkit.Result.YES;
      }
    });
  '';

  # Required for browser integration
  xdg.mime.enable = true;
  xdg.icons.enable = true;
}