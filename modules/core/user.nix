{ pkgs, inputs, username, host, ...}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs username host; };
    
    users.jwilger = {
      imports = 
        if (host == "gregor") then 
          [ ./../home/default.desktop.nix ] 
        else [ ./../home ];
      home.username = "jwilger";
      home.homeDirectory = "/home/jwilger";
      home.stateVersion = "24.11";
      programs.home-manager.enable = true;
    };
  };

  users.users.jwilger = {
    isNormalUser = true;
    description = "jwilger";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };
  nix.settings.allowed-users = [ "jwilger" ];
}
