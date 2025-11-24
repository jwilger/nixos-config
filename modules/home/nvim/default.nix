{ config, pkgs, inputs, ... }:
{
  programs.neovim = {
    enable = true;
    package = inputs.neovim-nightly.packages.${pkgs.stdenv.hostPlatform.system}.default;
    defaultEditor = false;
    vimAlias = true;
    viAlias = true;
    vimdiffAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;
  };

  systemd.user.tmpfiles.rules = [
    "L ${config.home.homeDirectory}/.config/nvim - - - - /etc/nixos/modules/home/nvim/nvim"
  ];
}
