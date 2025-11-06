{ pkgs, ... }:
{
  programs = {
    steam = {
      enable = true;
      extest.enable = true;
      gamescopeSession = {
        enable = true;
        args = [
          "--adaptive-sync" # VRR support
          "--hdr-enabled"
          "--mangoapp" # performance overlay
          "--rt"
          "--steam"
        ];
        steamArgs = [
          "-pipewire-dmabuf"
          "-tenfoot"
        ];
      };
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };
    gamescope = {
      enable = true;
      capSysNice = true;
    };
    appimage = {
      enable = true;
      binfmt = true;
    };
  };
}
