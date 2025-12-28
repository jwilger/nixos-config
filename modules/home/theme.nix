{ pkgs, ... }:
{
  home.packages = with pkgs; [
    catppuccin
  ];

  catppuccin = {
    enable = true;
    helix.enable = false;
    flavor = "mocha";
    accent = "lavender";
  };
}
