# 1Password configuration for jwilger user
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    _1password-gui
  ];

  # Enable native messaging host for browser integration
  home.file.".mozilla/native-messaging-hosts/com.1password.1password.json".source = 
    "${pkgs._1password-gui}/lib/mozilla/native-messaging-hosts/com.1password.1password.json";

  # Set up environment variables for 1Password
  home.sessionVariables = {
    SSH_AUTH_SOCK = "/home/jwilger/.1password/agent.sock";
  };

  # Additional shell environment setup
  programs.zsh.initExtra = ''
    if [[ -z "$SSH_AUTH_SOCK" ]]; then
      export SSH_AUTH_SOCK="/home/jwilger/.1password/agent.sock"
    fi
  '';

  # Firefox configuration
  programs.firefox = {
    enable = true;
    profiles.default = {
      settings = {
        # Enable native messaging for extensions
        "security.webauth.u2f" = true;
        "security.webauth.webauthn" = true;
        "security.webauth.webauthn.enabled" = true;
        "security.webauth.webauthn_enable_usbtoken" = true;
      };
    };
  };

  # Ensure 1Password directories exist
  home.file.".1password".source = config.lib.file.mkOutOfStoreSymlink "/home/jwilger/.1password";

  systemd.user.services = {
    onepassword-agent = {
      Unit = {
        Description = "1Password SSH Agent";
        Requires = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        Environment = "SSH_AUTH_SOCK=%h/.1password/agent.sock";
        ExecStart = "${pkgs._1password-gui}/bin/1password-cli agent";
        Restart = "on-failure";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };

  # Add XDG desktop integration
  xdg.desktopEntries."1password" = {
    name = "1Password";
    exec = "1password --silent";
    icon = "1password";
    terminal = false;
    categories = [ "Office" "Security" ];
  };

  # Ensure proper permissions for browser integration
  home.file.".config/1Password/settings/settings.json" = {
    text = builtins.toJSON {
      app = {
        browserAutoLaunch = true;
        browserAutoFill = true;
        enableAutoUpdate = false;
      };
    };
  };
}