{ pkgs, ... }:
{
  # Polkit 127 enables polkit-agent-helper with a strict sandbox; pam_u2f
  # needs access to hidraw devices and the authfile.
  # See: https://github.com/polkit-org/polkit/issues/622
  systemd.services."polkit-agent-helper@".serviceConfig = {
    StandardError = "journal";
    PrivateDevices = "no";
    DeviceAllow = [
      "/dev/urandom r"
      "char-hidraw rw"
    ];
    ProtectHome = "read-only";
  };

  # PC/SC daemon for smartcard operations
  services.pcscd.enable = true;

  # udev rules for YubiKey device access
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # Lock all sessions when YubiKey is removed
  # YubiKey 5 NFC MODEL_ID=0407, Vendor ID=1050 (Yubico)
  # Use `udevadm monitor --udev --environment` to verify for other models
  services.udev.extraRules = ''
    ACTION=="remove", \
    ENV{ID_BUS}=="usb", \
    ENV{ID_VENDOR_ID}=="1050", \
    ENV{ID_MODEL_ID}=="0407", \
    RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
  '';

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
      pinverification = 1; # Use FIDO2 PIN as authentication factor
    };
  };

  # Enable U2F for specific PAM services
  security.pam.services = {
    login.u2fAuth = true; # Console/TTY login
    sudo.u2fAuth = true; # Direct sudo command
    polkit-1.u2fAuth = true; # Polkit (run0, 1Password)
    cosmic-greeter.u2fAuth = true; # COSMIC display manager + screen lock
  };
}
