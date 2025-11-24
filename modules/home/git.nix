{ pkgs
, config
, lib
, ...
}:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "John Wilger";
        email = "john@johnwilger.com";
      };
      init.defaultBranch = "main";
      merge = {
        conflictstyle = "zdiff3";
        tool = "nvimdiff";
      };
      diff.tool = "nvimdiff";
      log.showSignature = true;
      gpg = {
        format = "ssh";
        ssh = {
          # Git requires ssh.* options to live in the [gpg "ssh"] subsection.
          allowedSignersFile = "${config.xdg.configHome}/ssh/allowed_signers";
          program = lib.getExe' pkgs._1password-gui "op-ssh-sign";
        };
      };
      pull.ff = "only";
      push.default = "current";
      safe.directory = "."; # Current directory
    };
    ignores = [
      # ignore direv files
      ".envrc"
      ".direnv/"
    ];

    signing = {
      format = "ssh";
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGwXlUIgMZDNewfvIyX5Gd1B1dIuLT7lH6N+2+FrSaSU";
      signByDefault = true;
    };

  };

  programs.difftastic = {
    enable = true;
    git.enable = true;
  };

  xdg.configFile."ssh/allowed_signers".text = ''
    john@johnwilger.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGwXlUIgMZDNewfvIyX5Gd1B1dIuLT7lH6N+2+FrSaSU
    johnwilger@artium.ai ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGwXlUIgMZDNewfvIyX5Gd1B1dIuLT7lH6N+2+FrSaSU
  '';
}
