{
  description = "FrostPhoenix's nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
  
    hypr-contrib.url = "github:hyprwm/contrib";
    hyprpicker.url = "github:hyprwm/hyprpicker";
  
    alejandra.url = "github:kamadorueda/alejandra/3.0.0";
  
  
    hyprland = {
      type = "git";
      url = "https://github.com/hyprwm/Hyprland";
      submodules = true;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin-bat = {
      url = "github:catppuccin/bat";
      flake = false;
    };
    catppuccin-cava = {
      url = "github:catppuccin/cava";
      flake = false;
    };
    catppuccin-starship = {
      url = "github:catppuccin/starship";
      flake = false;
    };
    catppuccin = {
      url = "github:catppuccin/nix";
    };
  };

  outputs = { catppuccin, nixpkgs, self, ...} @ inputs:
  {
    nixosConfigurations = {
      gregor = nixpkgs.lib.nixosSystem {
        modules = [
            catppuccin.nixosModules.catppuccin
            (import ./hosts/gregor)
          ];
        specialArgs = { host="gregor"; system="x86_64-linux"; username="jwilger"; inherit self inputs; };
      };
      vm = nixpkgs.lib.nixosSystem {
        modules = [
            catppuccin.nixosModules.catppuccin
            (import ./hosts/vm)
          ];
        specialArgs = { host="vm"; system="x86_64-linux"; username="jwilger"; inherit self inputs; };
      };
    };
  };
}
