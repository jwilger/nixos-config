{ username, ... }:
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
    "L /home/${username}/.config/nvim - - - - /home/${username}/nixos-config/modules/home/nvim/nvim"
  ];
}
