{ config, ... }:
{
  sops.defaultSopsFile = ./../../secrets/hindsight.yaml;

  sops.secrets."hindsight/openai-api-key" = { };
  sops.secrets."hindsight/pg-password" = {
    owner = "postgres";
  };

  # Rendered at activation to a root-only file under /run/secrets/rendered/.
  sops.templates."hindsight.env" = {
    owner = "hindsight";
    content = ''
      HINDSIGHT_API_LLM_API_KEY=${config.sops.placeholder."hindsight/openai-api-key"}
      HINDSIGHT_API_DATABASE_URL=postgresql://hindsight:${
        config.sops.placeholder."hindsight/pg-password"
      }@127.0.0.1:5432/hindsight
    '';
  };

  users = {
    groups.hindsight.gid = 980;
    users.hindsight = {
      autoSubUidGidRange = true;
      createHome = true;
      group = "hindsight";
      home = "/var/lib/hindsight";
      isSystemUser = true;
      linger = true;
      uid = 980;
    };
  };

  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers.hindsight = {
    image = "ghcr.io/vectorize-io/hindsight:latest-slim";
    environmentFiles = [ config.sops.templates."hindsight.env".path ];
    environment = {
      HINDSIGHT_API_HOST = "127.0.0.1";
      HINDSIGHT_API_PORT = "8888";
      HINDSIGHT_API_WORKER_ID = "hindsight-prod";
      HINDSIGHT_API_LLM_PROVIDER = "openai";
      HINDSIGHT_API_EMBEDDINGS_PROVIDER = "openai";
      HINDSIGHT_API_EMBEDDINGS_OPENAI_MODEL = "text-embedding-3-small";
      HINDSIGHT_API_RERANKER_PROVIDER = "rrf";
      HINDSIGHT_API_VECTOR_EXTENSION = "pgvector";
    };
    # Host networking: the container reaches PostgreSQL on 127.0.0.1:5432 and
    # binds the API on loopback. Do NOT set `ports` — it is ignored under host net.
    extraOptions = [ "--network=host" ];
    podman.user = "hindsight";
    autoStart = true;
  };

  # oci-containers generates `podman-hindsight.service`; gate it on the DB + init.
  systemd.services."podman-hindsight" = {
    after = [
      "postgresql.service"
      "hindsight-pg-init.service"
    ];
    requires = [
      "postgresql.service"
      "hindsight-pg-init.service"
    ];
  };
}
