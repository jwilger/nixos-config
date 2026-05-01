{ lib, pkgs, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    # RX 6700 XT is gfx1031, which isn't on AMD's official ROCm support
    # list. gfx1030 (RX 6800) is supported and the override works in
    # practice. Sets HSA_OVERRIDE_GFX_VERSION=10.3.0 in the unit env.
    rocmOverrideGfx = "10.3.0";
    models = "/home/ollama-models";
    host = "127.0.0.1";
    port = 11434;
    openFirewall = false;
  };

  systemd.tmpfiles.rules = [
    "d /home/ollama-models 0755 ollama ollama -"
  ];

  # Upstream sets ProtectHome=true; since models live on /home, the
  # unit needs /home visible in its mount namespace. Same workaround
  # as services/forgejo.nix.
  systemd.services.ollama.serviceConfig.ProtectHome = lib.mkForce false;
}
