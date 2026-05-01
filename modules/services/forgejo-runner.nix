{ lib, pkgs, ... }:
{
  # Gitea's act_runner speaks the same protocol as Forgejo's runner —
  # nixpkgs ships only the gitea variant, which works fine here.
  services.gitea-actions-runner = {
    package = pkgs.gitea-actions-runner;
    instances.gregor = {
      enable = true;
      name = "gregor";
      # The runner injects this URL into action containers as
      # GITHUB_SERVER_URL, so it must be reachable from inside Docker —
      # not just from the host. A loopback URL (http://localhost:3300)
      # works for the runner itself but breaks every actions/checkout
      # step inside the spawned container, which sees its own loopback.
      # Use the public URL; the small TLS hairpin through Caddy is the
      # cost of correctness.
      url = "https://git.johnwilger.com";
      # First-run registration token. Prefer the site-level token from
      # Site Admin → Actions → Runners → "Show registration token"
      # (multi-use, accepted by act_runner reliably). User-scope tokens
      # from /user/settings/actions/runners are sometimes rejected by
      # the registration API. Write it as a systemd EnvironmentFile:
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
      # Persist /nix across container jobs so flake-based builds reuse
      # a warm store instead of rebuilding from scratch every run.
      # valid_volumes is the runner's allowlist — without it, options'
      # bind mount is silently dropped. dockerd performs the mount as
      # root, so the host dir's ownership doesn't need to track the
      # runner's DynamicUser UID.
      settings = {
        container = {
          valid_volumes = [ "/var/cache/forgejo-runner-nix" ];
          options = "-v /var/cache/forgejo-runner-nix:/nix";
        };
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/forgejo-runner 0700 root root -"
    "d /var/cache/forgejo-runner-nix 0755 root root -"
  ];

  # The upstream register-runner ExecStartPre script doesn't check
  # `act_runner register`'s exit code, so a bad/expired token lets the
  # daemon start anyway, fail on missing .runner, and restart-loop
  # forever. Cap restarts so a broken token surfaces as a clean
  # `failed` state instead of burning CPU.
  systemd.services.gitea-runner-gregor = {
    startLimitIntervalSec = 60;
    startLimitBurst = 3;
    serviceConfig.RestartSec = lib.mkForce "10s";
  };
}
