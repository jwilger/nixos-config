{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  codexUser = "codex";
  projectsDirectory = "/home/${username}/projects";
in
{
  environment.systemPackages = [
    pkgs.acl
    (pkgs.writeShellApplication {
      name = "codex-as-user";
      text = ''
        exec ${config.security.wrapperDir}/sudo --login --user=${codexUser} -- codex "$@"
      '';
    })
    (pkgs.writeShellApplication {
      name = "codex-shell";
      text = ''
        exec ${config.security.wrapperDir}/sudo --login --user=${codexUser}
      '';
    })
  ];

  home-manager.users.${codexUser} =
    { config, ... }:
    let
      githubAuthKey = "${config.home.homeDirectory}/.ssh/github-auth_ed25519";
      githubSigningKey = "${config.home.homeDirectory}/.ssh/github-signing_ed25519";
      npmPrefix = "${config.home.homeDirectory}/.local/share/npm";
    in
    {
      home = {
        homeDirectory = "/home/${codexUser}";
        packages = [ pkgs.nodejs_22 ];
        sessionPath = [ "${npmPrefix}/bin" ];
        sessionVariables.NPM_CONFIG_PREFIX = npmPrefix;
        stateVersion = "24.11";
        username = codexUser;
      };

      programs.git = {
        enable = true;
        settings = {
          gpg.format = "ssh";
          init.defaultBranch = "main";
          pull.ff = "only";
          push.default = "current";
          user = {
            email = "john@johnwilger.com";
            name = "John Wilger";
            signingKey = githubSigningKey;
            useConfigOnly = true;
          };
        };
      };

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings."github.com" = {
          HostName = "github.com";
          IdentityAgent = "none";
          IdentityFile = githubAuthKey;
          IdentitiesOnly = true;
          User = "git";
        };
      };
    };

  users.groups.${codexUser} = { };

  users.users.${codexUser} = {
    description = "Isolated Codex CLI user";
    group = codexUser;
    hashedPassword = "!";
    home = "/home/${codexUser}";
    isNormalUser = true;
  };

  users.users.${username}.extraGroups = [ codexUser ];

  nix.settings.allowed-users = [ codexUser ];

  systemd.tmpfiles.rules = [
    "d /home/${codexUser}/.ssh 0700 ${codexUser} ${codexUser} -"
  ];

  security.sudo.extraRules = [
    {
      users = [ username ];
      runAs = codexUser;
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Bring existing project contents into the shared group model. Default ACLs
  # keep new files group-writable even when either user's umask is restrictive.
  system.activationScripts.codexProjectAccess = {
    deps = [ "users" ];
    text = ''
      if [[ -d ${lib.escapeShellArg projectsDirectory} ]]; then
        ${lib.getExe' pkgs.findutils "find"} ${lib.escapeShellArg projectsDirectory} -xdev \
          \( -type d -o -type f \) \
          -exec ${lib.getExe' pkgs.coreutils "chgrp"} ${codexUser} {} +
        ${lib.getExe' pkgs.findutils "find"} ${lib.escapeShellArg projectsDirectory} -xdev \
          -type f -exec ${lib.getExe' pkgs.coreutils "chmod"} g+rw {} +
        ${lib.getExe' pkgs.findutils "find"} ${lib.escapeShellArg projectsDirectory} -xdev \
          -type d -exec ${lib.getExe' pkgs.coreutils "chmod"} g+rws {} +
        ${lib.getExe' pkgs.findutils "find"} ${lib.escapeShellArg projectsDirectory} -xdev \
          -type d -exec ${lib.getExe' pkgs.acl "setfacl"} \
            --default --modify group:${codexUser}:rwx,mask::rwx {} +
      fi
    '';
  };
}
