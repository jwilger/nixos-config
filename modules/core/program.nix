{ pkgs, lib, ... }: 
{
  programs.dconf.enable = true;
  programs.zsh.enable = true;
  programs.gnupg.agent = {
    enable = true;
  };
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [];

  programs.appimage = {
    enable = true;
    binfmt = true;
  };
}
