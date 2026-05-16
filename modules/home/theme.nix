{ pkgs, ... }:
{
  home.packages = with pkgs; [
    catppuccin
  ];

  catppuccin = {
    enable = true;
    helix.enable = false;
    starship.enable = false;
    flavor = "mocha";
    accent = "lavender";
  };
}
