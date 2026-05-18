{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Expose the forgejo CLI system-wide so admin commands like
  # `sudo -u forgejo forgejo admin user create …` work without
  # hardcoded /nix/store paths.
  environment.systemPackages = [ config.services.forgejo.package ];

  services.forgejo = {
    enable = true;
    stateDir = "/home/forgejo";
    database = {
      type = "postgres";
      socket = "/run/postgresql";
      user = "forgejo";
      name = "forgejo";
    };
    settings = {
      server = {
        DOMAIN = "git.johnwilger.com";
        ROOT_URL = "https://git.johnwilger.com/";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 3300;
        SSH_PORT = 2222;
        START_SSH_SERVER = true;
        SSH_LISTEN_HOST = "0.0.0.0";
      };
      service.DISABLE_REGISTRATION = true;
      security.INSTALL_LOCK = true;
      actions = {
        ENABLED = true;
        DEFAULT_ACTIONS_URL = "github";
      };
      webhook.ALLOWED_HOST_LIST = "loopback,external";
      # Release/issue attachments live on Backblaze B2 (S3-compatible) instead
      # of local disk. New uploads go straight to B2; existing files must be
      # moved once with `forgejo migrate-storage` (see notes below).
      "storage.attachments" = {
        STORAGE_TYPE = "minio";
        MINIO_ENDPOINT = "s3.us-west-004.backblazeb2.com";
        MINIO_BUCKET = "forgejo-release-assets";
        MINIO_LOCATION = "us-west-004";
        MINIO_USE_SSL = true;
        MINIO_BASE_PATH = "attachments/";
      };
      "repository.signing" = {
        FORMAT = "ssh";
        SIGNING_KEY = "/home/forgejo/.ssh/forgejo_signing.pub";
        SIGNING_NAME = "Forgejo";
        SIGNING_EMAIL = "forgejo@git.johnwilger.com";
        DEFAULT_TRUST_MODEL = "committer";
        INITIAL_COMMIT = "always";
        CRUD_ACTIONS = "always";
        WIKI = "always";
        MERGES = "always";
      };
    };
  };

  # B2 application key for the attachment storage bucket. The forgejo module
  # injects these into the [storage.attachments] section of app.ini at start,
  # so the credentials never land in the Nix store.
  services.forgejo.secrets."storage.attachments" = {
    MINIO_ACCESS_KEY_ID = config.sops.secrets."forgejo/b2-key-id".path;
    MINIO_SECRET_ACCESS_KEY = config.sops.secrets."forgejo/b2-app-key".path;
  };

  sops.secrets."forgejo/b2-key-id" = {
    sopsFile = ./../../secrets/forgejo.yaml;
    owner = "forgejo";
  };
  sops.secrets."forgejo/b2-app-key" = {
    sopsFile = ./../../secrets/forgejo.yaml;
    owner = "forgejo";
  };

  # The upstream forgejo module sets ProtectHome=true, which hides /home
  # from the unit's mount namespace. We put stateDir on /home so it
  # rides along on btrbk's nightly /home → /archive snapshots, so we
  # need /home visible to the unit.
  systemd.services.forgejo.serviceConfig.ProtectHome = lib.mkForce false;

  # Forgejo only writes /home/forgejo/data/home/.gitconfig once on first
  # run, so SIGNING_FORMAT changes in app.ini do not propagate. Force
  # gpg.format=ssh and user.signingkey on every start so merge-commit
  # signing actually invokes ssh-keygen instead of gpg.
  systemd.services.forgejo.preStart = lib.mkAfter ''
    GITCONFIG=/home/forgejo/data/home/.gitconfig
    if [ -f "$GITCONFIG" ]; then
      ${pkgs.git}/bin/git config --file "$GITCONFIG" gpg.format ssh
      ${pkgs.git}/bin/git config --file "$GITCONFIG" user.signingkey /home/forgejo/.ssh/forgejo_signing.pub
    fi
  '';
}
