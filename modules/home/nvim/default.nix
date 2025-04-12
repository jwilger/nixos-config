{ ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    vimdiffAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;
  };

  systemd.user.tmpfiles.rules = [
    "L /home/jwilger/.config/nvim - - - - /home/jwilger/nixos-config/modules/home/nvim/nvim"
  ];
}
