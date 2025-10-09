{ pkgs, ... }:
{
  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" "ssh" ];
  };

  # Ensure the keyring is unlocked on login
  # The PAM integration should handle this automatically via the system config
}
