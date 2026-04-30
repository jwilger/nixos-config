{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.teamcity;
  # JetBrains shell scripts call sh/awk/ps/which/etc by name. The NixOS
  # systemd-service `path` option augments the unit's PATH so these
  # resolve.
  teamcityPath = with pkgs; [
    bash
    gawk
    gzip
    hostname # agent calls `hostname` via Java ProcessBuilder
    procps
    util-linux
    which
  ];
  teamcityPkg = pkgs.stdenvNoCC.mkDerivation {
    pname = "teamcity-server";
    version = "2025.11.4";
    src = pkgs.fetchurl {
      url = "https://download.jetbrains.com/teamcity/TeamCity-2025.11.4.tar.gz";
      sha256 = "01kmqv5fpfkvzh2hlm9rxvcpb38i040hrx2qrsp3dnawd5cpg0j7";
    };
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/TeamCity
      cp -r . $out/TeamCity/
      chmod -R u+w $out
    '';
  };

  # TeamCity assumes its installation directory is writable (writes
  # conf/teamcity-startup.properties, mutates webapps/, agent writes
  # logs/temp/work/system in-tree). The Nix store is read-only, so
  # ExecStartPre rsyncs the store package into a writable home on
  # first start (and on every package version change). Runtime data
  # (TEAMCITY_DATA_PATH, logs, agent identity) lives outside the
  # install dir so version bumps don't blow it away.
  # Empty the directory's contents in place. Can't `rm -rf $dir`
  # because the parent /home/teamcity is root-owned, so the unit's
  # user can't unlink the dir itself — only its contents.
  serverInstallScript = pkgs.writeShellScript "teamcity-server-install" ''
    set -eu
    install_dir=${cfg.installDir.server}
    marker="$install_dir/.installed-from"
    if [ "$(cat "$marker" 2>/dev/null)" != "${teamcityPkg}" ]; then
      find "$install_dir" -mindepth 1 -delete
      cp -rT ${teamcityPkg}/TeamCity "$install_dir"
      chmod -R u+w "$install_dir"
      echo "${teamcityPkg}" > "$marker"
    fi
  '';

  agentInstallScript = pkgs.writeShellScript "teamcity-agent-install" ''
    set -eu
    install_dir=${cfg.agent.dataDir}
    config_dir=${cfg.agent.configDir}
    marker="$install_dir/.installed-from"
    mkdir -p "$config_dir"
    if [ "$(cat "$marker" 2>/dev/null)" != "${teamcityPkg}" ]; then
      find "$install_dir" -mindepth 1 -delete
      cp -rT ${teamcityPkg}/TeamCity/buildAgent "$install_dir"
      chmod -R u+w "$install_dir"
      echo "${teamcityPkg}" > "$marker"
    fi

    # Persistent buildAgent.properties (kept outside install_dir so
    # the agent keeps its identity/auth token across TeamCity upgrades).
    if [ ! -f "$config_dir/buildAgent.properties" ]; then
      cp "$install_dir/conf/buildAgent.dist.properties" "$config_dir/buildAgent.properties"
      sed -i \
        -e 's|^serverUrl=.*|serverUrl=http://localhost:8111|' \
        -e 's|^name=.*|name=gregor-agent|' \
        "$config_dir/buildAgent.properties"
    fi
    ln -sfn "$config_dir/buildAgent.properties" "$install_dir/conf/buildAgent.properties"
  '';
in
{
  options.services.teamcity = {
    enable = lib.mkEnableOption "TeamCity CI server";
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/home/teamcity/data";
    };
    logsDir = lib.mkOption {
      type = lib.types.path;
      default = "/home/teamcity/logs";
    };
    installDir.server = lib.mkOption {
      type = lib.types.path;
      default = "/home/teamcity/server";
      description = "Writable copy of the TeamCity server distribution.";
    };
    heapMax = lib.mkOption {
      type = lib.types.str;
      default = "2g";
    };
    jdk = lib.mkOption {
      type = lib.types.package;
      default = pkgs.jdk21;
    };
    agent.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    agent.dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/home/teamcity/agent";
      description = "Agent install/runtime directory (writable copy of buildAgent).";
    };
    agent.configDir = lib.mkOption {
      type = lib.types.path;
      default = "/home/teamcity/agent-config";
      description = "Persistent agent config (buildAgent.properties + auth token).";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.teamcity = {
      isSystemUser = true;
      group = "teamcity";
      home = cfg.dataDir;
    };
    users.groups.teamcity = { };

    users.users.teamcity-agent = lib.mkIf cfg.agent.enable {
      isSystemUser = true;
      group = "teamcity-agent";
      home = cfg.agent.dataDir;
    };
    users.groups.teamcity-agent = lib.mkIf cfg.agent.enable { };

    systemd.tmpfiles.rules = [
      "d /home/teamcity              0755 root           root           -"
      "d ${cfg.dataDir}              0750 teamcity       teamcity       -"
      "d ${cfg.logsDir}              0750 teamcity       teamcity       -"
      "d ${cfg.installDir.server}    0750 teamcity       teamcity       -"
      "d ${cfg.dataDir}/lib          0750 teamcity       teamcity       -"
      "d ${cfg.dataDir}/lib/jdbc     0750 teamcity       teamcity       -"
      "L+ ${cfg.dataDir}/lib/jdbc/postgresql.jar - - - - ${pkgs.postgresql_jdbc}/share/java/postgresql-jdbc.jar"
    ]
    ++ lib.optionals cfg.agent.enable [
      "d ${cfg.agent.dataDir}        0750 teamcity-agent teamcity-agent -"
      "d ${cfg.agent.configDir}      0750 teamcity-agent teamcity-agent -"
    ];

    systemd.services.teamcity = {
      description = "TeamCity server";
      after = [
        "postgresql.service"
        "network-online.target"
      ];
      wants = [
        "postgresql.service"
        "network-online.target"
      ];
      wantedBy = [ "multi-user.target" ];
      path = teamcityPath;
      environment = {
        TEAMCITY_DATA_PATH = cfg.dataDir;
        TEAMCITY_LOGS_PATH = cfg.logsDir;
        JAVA_HOME = "${cfg.jdk}";
        JRE_HOME = "${cfg.jdk}";
        TEAMCITY_SERVER_MEM_OPTS = "-Xmx${cfg.heapMax} -Xms512m";
      };
      serviceConfig = {
        Type = "simple";
        User = "teamcity";
        Group = "teamcity";
        WorkingDirectory = cfg.installDir.server;
        ExecStartPre = serverInstallScript;
        ExecStart = "${cfg.installDir.server}/bin/teamcity-server.sh run";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };

    systemd.services.teamcity-agent = lib.mkIf cfg.agent.enable {
      description = "TeamCity build agent";
      after = [ "teamcity.service" ];
      wants = [ "teamcity.service" ];
      wantedBy = [ "multi-user.target" ];
      path = teamcityPath;
      environment = {
        JAVA_HOME = "${cfg.jdk}";
        JRE_HOME = "${cfg.jdk}";
        TEAMCITY_AGENT_OPTS = "-Xmx512m";
      };
      serviceConfig = {
        Type = "simple";
        User = "teamcity-agent";
        Group = "teamcity-agent";
        WorkingDirectory = cfg.agent.dataDir;
        ExecStartPre = agentInstallScript;
        ExecStart = "${cfg.agent.dataDir}/bin/agent.sh run";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };
  };
}
