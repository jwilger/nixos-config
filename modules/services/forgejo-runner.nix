{ pkgs, ... }:
{
  # Gitea's act_runner speaks the same protocol as Forgejo's runner —
  # nixpkgs ships only the gitea variant, which works fine here.
  services.gitea-actions-runner = {
    package = pkgs.gitea-actions-runner;
    instances.gregor = {
      enable = true;
      name = "gregor";
      # Talk to Forgejo over loopback to skip Caddy/TLS — the runner
      # lives on the same host as the server.
      url = "http://localhost:3300";
      # First-run registration token. Mint one via Forgejo's
      # Site Admin → Actions → Runners → "Create new runner",
      # then write it as a systemd EnvironmentFile (`TOKEN=...`):
      #   sudo install -d -m 0700 /var/lib/forgejo-runner
      #   echo 'TOKEN=<paste>' | sudo tee /var/lib/forgejo-runner/token
      #   sudo chmod 0400 /var/lib/forgejo-runner/token
      # After registration the runner persists its auth in its state
      # dir; the file can be removed but we leave it so re-registration
      # works if the state dir is wiped.
      tokenFile = "/var/lib/forgejo-runner/token";
      labels = [
        "docker:docker://node:20-bookworm"
        "native:host"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/forgejo-runner 0700 root root -"
  ];
}
