{ ... }:
{
  security.rtkit.enable = true;
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = true;
  security.pam.services.hyprlock = {
    enable = true;
  };

  # Enable gnome-keyring PAM integration to unlock keyring on login
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
}
