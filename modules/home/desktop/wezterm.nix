{ pkgs, ... }:
{
  # Use the latest WezTerm package for better SSH agent forwarding support
  home.packages = with pkgs; [
    wezterm
  ];
  
  programs.wezterm = {
    enable = true;
    extraConfig = builtins.readFile ./wezterm.lua;
  };
}

