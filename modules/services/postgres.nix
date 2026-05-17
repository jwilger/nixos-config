{
  config,
  lib,
  ...
}:
{
  services.postgresql = {
    enable = true;
    extensions = ps: [ ps.pgvector ];
    ensureDatabases = [
      "forgejo"
      "hindsight"
    ];
    ensureUsers = [
      {
        name = "forgejo";
        ensureDBOwnership = true;
      }
      {
        name = "hindsight";
        ensureDBOwnership = true;
      }
    ];
    settings.password_encryption = "scram-sha-256";
    authentication = lib.mkAfter ''
      host  hindsight  hindsight  127.0.0.1/32  scram-sha-256
      host  hindsight  hindsight  ::1/128       scram-sha-256
    '';
  };

  # `ensureUsers` creates a passwordless role and cannot create extensions.
  # This idempotent oneshot enables pgvector and sets the hindsight role's
  # password, ordered after PostgreSQL is up and before the Hindsight container.
  systemd.services.hindsight-pg-init = {
    description = "Enable pgvector + set password for the hindsight DB";
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ config.services.postgresql.package ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "postgres";
    };
    script = ''
      until pg_isready -q; do sleep 1; done
      psql -d hindsight -tAc "CREATE EXTENSION IF NOT EXISTS vector;"
      PW=$(cat ${config.sops.secrets."hindsight/pg-password".path})
      psql -d postgres -tAc "ALTER ROLE hindsight WITH LOGIN PASSWORD '$PW';"
    '';
  };
}
