{ pkgs, username, ... }:
{
  imports = [
    ./../../modules/darwin
  ];

  # macOS system settings
  networking.hostName = "darwin";

  # Timezone (matching your Linux config)
  time.timeZone = "America/Los_Angeles";

  # Enable sudo authentication with Touch ID
  security.pam.enableSudoTouchIdAuth = true;

  # System-wide packages
  environment.systemPackages = with pkgs; [
    wget
    git
  ];

  # Auto upgrade nix package and the daemon service
  services.nix-daemon.enable = true;

  # Used for backwards compatibility, please read the changelog before changing
  system.stateVersion = 5;

  # Home Manager integration
  home-manager.users.${username} = {
    imports = [
      ./../../modules/home
      ./../../modules/home/darwin
    ];

    home.username = "${username}";
    home.homeDirectory = "/Users/${username}";
    home.stateVersion = "24.11";
    programs.home-manager.enable = true;
  };

  # macOS-specific user settings
  users.users.${username} = {
    name = "${username}";
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  # Enable zsh system-wide
  programs.zsh.enable = true;
}
