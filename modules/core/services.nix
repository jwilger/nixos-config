{ pkgs, ... }:
{
  # BcacheFS scrub service & timer
  systemd.services.bcachefs-scrub = {
    description = "Scrub BcacheFS filesystems";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = [ "${pkgs.bcachefs-tools}/bin/bcachefs" "scrub" "/" ];
    };
    wantedBy = [ "multi-user.target" ];
  };
  systemd.timers.bcachefs-scrub = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun 03:00";
      Persistent = true;
    };
  };
  services = {
    gvfs.enable = true;
    gnome.gnome-keyring.enable = true;
    dbus.enable = true;
    fstrim.enable = true;
  };
  services.logind.extraConfig = ''
    # don’t shutdown when power button is short-pressed
    HandlePowerKey=ignore
  '';
  
  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      # Disable password-based SSH authentication
      PasswordAuthentication = false;
      # Deny direct root login
      PermitRootLogin = "no";
    };
  };
  # Block repeated SSH attacks
  services.fail2ban = {
    enable = true;
  };
  # Ensure system time stays accurate
    services.timesyncd = {
      enable = true;
    };
    # Enable battery and power status management
    services.upower.enable = true;
    # Configure logrotate for real rotations
    # Configure logrotate for real rotations
    services.logrotate = {
      enable = true;
      # debug option removed; consider `verbose = true` if needed
      # debug = false;
    };
}
