{ inputs, ... }: 
{
  imports = [ (import ./hyprland.nix) ]
    ++ [ (import ./config.nix) ]
    ++ [ (import ./hyprpaper.nix) ]
    ++ [ (import ./hyprlock.nix) ]
    ++ [ (import ./variables.nix) ]
    ++ [ (import ./wlogout.nix) ]
    ++ [ (import ./hypridle.nix) ]
    ++ [ inputs.hyprland.homeManagerModules.default ];
}
