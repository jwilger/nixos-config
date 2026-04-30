{
  pkgs,
  inputs,
  username,
  host,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs username host; };
    # When home-manager wants to manage a file that already exists
    # outside of nix (e.g. an app wrote a default config on first run),
    # rename the existing file to <name>.hm-backup instead of aborting
    # activation. Without this, a single stray config file silently
    # blocks the entire home-manager generation from being linked in.
    backupFileExtension = "hm-backup";

    users.${username} = {
      home.username = "${username}";
      home.homeDirectory = "/home/${username}";
      home.stateVersion = "24.11";
      programs.home-manager.enable = true;
      imports = [
        inputs.catppuccin.homeModules.catppuccin
      ];
    };
  };

  users.groups.${username} = {
    gid = 1000;
  };

  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    uid = 1000;
    group = "${username}";
    extraGroups = [
      "networkmanager"
      "wheel"
      "lp"
      "lpadmin"
    ];
    shell = pkgs.zsh;
  };
  nix.settings.allowed-users = [ "${username}" ];
}
