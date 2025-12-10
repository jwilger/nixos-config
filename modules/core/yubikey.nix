{ pkgs, ... }:
{
  # PC/SC daemon for smartcard operations
  services.pcscd.enable = true;

  # udev rules for YubiKey device access
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # System packages for YubiKey management
  environment.systemPackages = with pkgs; [
    yubikey-personalization
    yubico-piv-tool
    pam_u2f
  ];

  # PAM U2F configuration
  security.pam.u2f = {
    enable = true;
    control = "sufficient"; # OR semantics: YubiKey OR password
    settings = {
      cue = true; # Show "Please touch the device" prompt
    };
  };

  # Enable U2F for specific PAM services
  security.pam.services = {
    login.u2fAuth = true; # Console/TTY login
    sudo.u2fAuth = true; # Direct sudo command
    polkit-1.u2fAuth = true; # Polkit (run0, 1Password)
    cosmic-greeter.u2fAuth = true; # Display manager + screen lock
  };
}
