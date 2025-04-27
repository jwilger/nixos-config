{ pkgs, ... }:
{
  home.packages = with pkgs; [
    catppuccin
  ];

  catppuccin = {
    enable = true;
    nvim.enable = false;
    flavor = "mocha";
    accent = "lavender";
  };
}
