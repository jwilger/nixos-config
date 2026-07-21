{
  config,
  lib,
  pkgs,
  ...
}:
let
  githubOrgUrl = "https://github.com/jwilger";

  # Docker-in-Docker: job containers (including service containers like
  # `services: postgres:`) run inside an isolated nested Docker daemon on
  # its own bridge network, rather than talking to gregor's host Docker
  # daemon directly. This avoids one problem at the root instead of via
  # per-job patches: a job's `services: postgres: ports: ["5432:5432"]`
  # publishes on the DinD container's own bridge-network interface, not
  # gregor's real host interface, so it can never collide with gregor's
  # actual system Postgres (used by Hindsight) on the real
  # 5432. NOTE: this does NOT remove the need for the systemd sandboxing
  # loosening below -- confirmed empirically (a job still hit "Could not
  # find a part of the path '/proc/1/cgroup'" after DinD was live). The
  # outer runner process itself performs cgroup/proc introspection as part
  # of its own Docker-API-client-side logic regardless of which daemon
  # DOCKER_HOST ultimately points at, so both fixes are needed together.
  dindRunDir = "/run/github-runner-dind";
  dindStateDir = "/var/lib/github-runner-dind";
  dindSocket = "${dindRunDir}/docker.sock";
  dindContainerName = "github-runner-dind";
  dindNetworkName = "github-runner-dind";
  dindImage = "docker.io/library/docker:27-dind";
  dindExecStart = lib.concatStringsSep " " [
    "${pkgs.docker}/bin/docker"
    "run"
    "--rm"
    "--name=${dindContainerName}"
    "--privileged"
    "--network=${dindNetworkName}"
    "--env=DOCKER_TLS_CERTDIR="
    "--volume=${dindRunDir}:${dindRunDir}"
    "--volume=${dindStateDir}:/var/lib/docker"
    dindImage
    "dockerd"
    "--host=unix://${dindSocket}"
    "--data-root=/var/lib/docker"
    "--pidfile=${dindRunDir}/docker.pid"
  ];
in
{
  sops.secrets."github-runner-token" = {
    sopsFile = ./../../secrets/github-runner.yaml;
    key = "token";
    owner = "github-runner";
  };

  users.users.github-runner = {
    isSystemUser = true;
    group = "github-runner";
  };
  users.groups.github-runner = { };

  # A runner cache directory is not a real shared Nix store when jobs run
  # inside Docker-in-Docker, isolated
  # from the host Nix installation entirely, so that directory's
  # `var/nix/db` is root-owned 0700 and was never meant to be written by
  # an unprivileged user directly. Pointing NIX_REMOTE at it (an earlier
  # approach here) failed every job that ran real Nix commands with
  # "Permission denied" on its lock file. The correct fix is simpler:
  # github-runner's `nix develop`/`nix shell` commands run natively on the
  # host (Nix itself is not containerized here, only Docker jobs are), so
  # they should just use gregor's normal system-wide Nix daemon, which is
  # already warm/persistent across reboots like everything else on this
  # machine -- no separate store needed. That daemon restricts callers via
  # `allowed-users` (see modules/core/user.nix), so github-runner needs an
  # explicit grant.
  nix.settings.allowed-users = [ "github-runner" ];

  systemd.tmpfiles.rules = [
    "d ${dindRunDir} 0750 root github-runner -"
    "d ${dindStateDir} 0700 root root -"
  ];

  systemd.services.github-runner-dind = {
    description = "GitHub Actions Runner Docker-in-Docker Daemon";
    after = [ "docker.service" ];
    path = [
      pkgs.coreutils
      pkgs.docker
    ];
    requires = [ "docker.service" ];
    unitConfig.RequiresMountsFor = [ dindStateDir ];
    wantedBy = [ "multi-user.target" ];

    preStart = ''
      install -d -m 0750 -o root -g github-runner ${dindRunDir}
      install -d -m 0700 -o root -g root ${dindStateDir}
      rm -f ${dindSocket}
      docker network inspect ${dindNetworkName} >/dev/null 2>&1 \
        || docker network create ${dindNetworkName} >/dev/null
      docker rm -f ${dindContainerName} >/dev/null 2>&1 || true
    '';

    postStart = ''
      i=0
      while [ "$i" -lt 60 ]; do
        if [ -S ${dindSocket} ]; then
          chown root:github-runner ${dindSocket}
          chmod 0660 ${dindSocket}
          exit 0
        fi
        i=$((i + 1))
        sleep 1
      done
      echo "ERROR: timed out waiting for ${dindSocket}" >&2
      exit 1
    '';

    serviceConfig = {
      Type = "simple";
      ExecStart = dindExecStart;
      ExecStop = "-${pkgs.docker}/bin/docker stop ${dindContainerName}";
      Restart = "on-failure";
      RestartSec = lib.mkForce "10s";
    };
  };

  # Unlike a GitHub-hosted runner (fresh VM every job), this DinD daemon is
  # long-lived across many CI runs. Confirmed empirically: a job's fresh
  # `services: postgres:` container reused a stale data volume from an
  # earlier run and inherited its old credentials, since the postgres
  # image only applies POSTGRES_USER/POSTGRES_PASSWORD on an empty data
  # directory -- causing "password authentication failed" even though the
  # workflow's env vars were correct. Prune dangling volumes frequently so
  # every service container effectively starts from empty state, matching
  # GitHub-hosted semantics.
  systemd.services.github-runner-dind-volume-prune = {
    description = "Prune stale Docker volumes in the GitHub runner DinD daemon";
    after = [ "github-runner-dind.service" ];
    requires = [ "github-runner-dind.service" ];
    path = [ pkgs.docker ];
    environment.DOCKER_HOST = "unix://${dindSocket}";
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      docker volume prune -f
    '';
  };

  systemd.timers.github-runner-dind-volume-prune = {
    description = "Periodic GitHub runner DinD volume prune";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnActiveSec = "30s";
      OnUnitActiveSec = "1m";
      RandomizedDelaySec = "10s";
    };
  };

  services.github-runners.jwilger = {
    enable = true;
    name = "gregor";
    url = githubOrgUrl;
    tokenFile = config.sops.secrets."github-runner-token".path;
    tokenType = "access"; # fine-grained PAT, not a short-lived registration token
    user = "github-runner";
    group = "github-runner";
    replace = true; # allow re-registering under the same name on config changes
    extraLabels = [ "self-hosted-gregor" ];
    extraPackages = with pkgs; [
      git
      gnutar
      gzip
      jq
      docker
      unzip
      curl
    ];
    # No ephemeral mode: gregor's whole point is the warm, persistent Nix
    # store across runs. Ephemeral
    # would wipe the state directory after every single job.
    ephemeral = false;
    extraEnvironment = {
      # Route every docker/service-container operation the runner performs
      # at the DinD daemon instead of gregor's host Docker daemon.
      DOCKER_HOST = "unix://${dindSocket}";
    };
    serviceOverrides = {
      # Still required even with DinD in place -- see the comment above
      # dindExecStart. The outer runner process's own cgroup/proc
      # introspection during container setup fails without this,
      # independent of which Docker daemon it talks to.
      ProtectControlGroups = false;
      ProtectProc = "default";
      PrivateDevices = false;
      RestrictNamespaces = false;
    };
  };

  # The module has no after/wants option, so these are set directly on the
  # generated unit. Also wait for the DinD socket to actually be usable
  # before the runner starts accepting jobs.
  systemd.services.github-runner-jwilger = {
    after = [ "github-runner-dind.service" ];
    wants = [ "github-runner-dind.service" ];
    preStart = lib.mkAfter ''
      i=0
      while [ "$i" -lt 60 ]; do
        if [ -S ${dindSocket} ] && [ -r ${dindSocket} ] && [ -w ${dindSocket} ]; then
          break
        fi
        i=$((i + 1))
        sleep 1
      done
      if [ "$i" -eq 60 ]; then
        echo "ERROR: ${dindSocket} is not ready for github-runner-jwilger." >&2
        exit 1
      fi
    '';
  };
}
