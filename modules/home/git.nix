{ pkgs, config,... }: 
{
  programs.git = {
    enable = true;
    userName = "John Wilger";
    userEmail = "john@johnwilger.com";

    ignores = [
      # ignore direv files
      ".envrc"
      ".direnv/"
    ];
    difftastic = {
      enable = true;
    };

    signing = {
      format = "ssh";
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGwXlUIgMZDNewfvIyX5Gd1B1dIuLT7lH6N+2+FrSaSU";
      signByDefault = true;
      signer = "git-ssh-sign";
    };

    extraConfig = {
      init.defaultBranch = "main";
      merge.conflictstyle = "zdiff3";
      merge.tool = "nvimdiff";
      diff.tool = "nvimdiff";
      log.showSignature = true;
      gpg = {
        ssh.allowedSignersFile = "${config.home.homeDirectory}/${config.xdg.configFile."ssh/allowed_signers".target}";
      };
      pull = {
        ff = "only";
      };
      push = {
        default = "current";
      };
      safe.directory = ".";  # Current directory
    };
  };

  xdg.configFile."ssh/allowed_signers".text = ''
    john@johnwilger.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGwXlUIgMZDNewfvIyX5Gd1B1dIuLT7lH6N+2+FrSaSU
    johnwilger@artium.ai ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGwXlUIgMZDNewfvIyX5Gd1B1dIuLT7lH6N+2+FrSaSU
  '';
}
