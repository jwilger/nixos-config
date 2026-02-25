{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.services.ironclaw;

  ironclawPkg = pkgs.callPackage ../../pkgs/ironclaw {
    ironclaw-src = inputs.ironclaw-src;
  };

  # Generate the Telegram capabilities JSON from NixOS options
  telegramCapabilitiesJson = pkgs.writeText "telegram.capabilities.json" (
    builtins.toJSON {
      dm_policy = cfg.telegram.dmPolicy;
      allow_from = cfg.telegram.allowedUserIds;
      owner_id = cfg.telegram.ownerId;
      bot_username = cfg.telegram.botUsername;
      respond_to_all_group_messages = cfg.telegram.respondToAllGroupMessages;
    }
  );

  # Generate the bootstrap .env file (non-secret values only)
  bootstrapEnv = pkgs.writeText "ironclaw-bootstrap.env" ''
    DATABASE_URL=postgresql:///ironclaw?host=/run/postgresql&port=${toString cfg.postgresPort}
    SECRETS_MODE=env
    LLM_BACKEND=${cfg.llm.backend}
    LLM_MODEL=${cfg.llm.model}
  '';

  # Script to resolve secrets from 1Password and write the runtime env file
  secretsSetupScript = pkgs.writeShellScript "ironclaw-secrets-setup" ''
    set -euo pipefail
    RUNTIME_DIR="/run/ironclaw"
    mkdir -p "$RUNTIME_DIR"
    chmod 700 "$RUNTIME_DIR"

    # Start with bootstrap (non-secret) env vars
    cp ${bootstrapEnv} "$RUNTIME_DIR/env"

    ${
      if cfg.secrets.onePassword.enable then
        ''
          # Load 1Password service account token
          export OP_SERVICE_ACCOUNT_TOKEN="$(cat ${cfg.secrets.onePassword.serviceAccountTokenFile})"

          # Fetch secrets from 1Password and append to env file
          echo "ANTHROPIC_API_KEY=$(${pkgs._1password-cli}/bin/op read '${cfg.secrets.onePassword.anthropicApiKeyRef}')" >> "$RUNTIME_DIR/env"
          ${lib.optionalString (cfg.secrets.onePassword.telegramBotTokenRef != null) ''
            echo "TELEGRAM_BOT_TOKEN=$(${pkgs._1password-cli}/bin/op read '${cfg.secrets.onePassword.telegramBotTokenRef}')" >> "$RUNTIME_DIR/env"
          ''}
        ''
      else
        ''
          # Using manual environment file for secrets
          ${lib.optionalString (cfg.secrets.environmentFile != null) ''
            cat ${cfg.secrets.environmentFile} >> "$RUNTIME_DIR/env"
          ''}
        ''
    }

    chmod 600 "$RUNTIME_DIR/env"
    chown ironclaw:ironclaw "$RUNTIME_DIR/env"
  '';

  # Script to set up IronClaw data directory and config files
  dataSetupScript = pkgs.writeShellScript "ironclaw-data-setup" ''
    set -euo pipefail

    # Set up channels directory with WASM files from the package
    mkdir -p ${cfg.dataDir}/.ironclaw/channels
    cp -f ${cfg.package}/share/ironclaw/channels/telegram.wasm ${cfg.dataDir}/.ironclaw/channels/
    cp -f ${telegramCapabilitiesJson} ${cfg.dataDir}/.ironclaw/channels/telegram.capabilities.json

    # Create bootstrap .env so ironclaw can find DATABASE_URL
    cp -f ${bootstrapEnv} ${cfg.dataDir}/.ironclaw/.env
    chmod 600 ${cfg.dataDir}/.ironclaw/.env
  '';
in
{
  options.services.ironclaw = {
    enable = lib.mkEnableOption "IronClaw AI assistant";

    package = lib.mkOption {
      type = lib.types.package;
      default = ironclawPkg;
      description = "The IronClaw package to use.";
    };

    postgresPort = lib.mkOption {
      type = lib.types.port;
      default = 5433;
      description = "Port for the PostgreSQL instance used by IronClaw.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/ironclaw";
      description = "Data directory for IronClaw.";
    };

    # --- LLM configuration ---
    llm = {
      backend = lib.mkOption {
        type = lib.types.enum [
          "anthropic"
          "openai"
          "nearai"
          "ollama"
          "openai-compatible"
        ];
        default = "anthropic";
        description = "LLM inference backend.";
      };

      model = lib.mkOption {
        type = lib.types.str;
        default = "claude-sonnet-4-20250514";
        description = "LLM model identifier.";
      };
    };

    # --- Telegram channel configuration ---
    telegram = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable the Telegram channel.";
      };

      botUsername = lib.mkOption {
        type = lib.types.str;
        description = "Telegram bot username (without @).";
        example = "MikeHatbot";
      };

      ownerId = lib.mkOption {
        type = lib.types.int;
        description = "Telegram user ID of the bot owner.";
      };

      allowedUserIds = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of Telegram user ID strings allowed to DM the bot.";
      };

      dmPolicy = lib.mkOption {
        type = lib.types.enum [
          "allowlist"
          "open"
        ];
        default = "allowlist";
        description = "DM policy: 'allowlist' restricts to allowedUserIds, 'open' allows anyone.";
      };

      respondToAllGroupMessages = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether the bot responds to all group messages.";
      };
    };

    # --- Secrets configuration ---
    secrets = {
      onePassword = {
        enable = lib.mkEnableOption "1Password secrets injection";

        serviceAccountTokenFile = lib.mkOption {
          type = lib.types.str;
          description = "Path to a file containing the 1Password Service Account token.";
          example = "/etc/ironclaw/op-token";
        };

        anthropicApiKeyRef = lib.mkOption {
          type = lib.types.str;
          description = "1Password secret reference for the Anthropic API key.";
          example = "op://Private/IronClaw/anthropic-api-key";
        };

        telegramBotTokenRef = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "1Password secret reference for the Telegram bot token.";
          example = "op://Private/IronClaw/telegram-bot-token";
        };
      };

      environmentFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to an environment file with secrets (fallback when not using 1Password).";
        example = "/etc/ironclaw/secrets.env";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.secrets.onePassword.enable || cfg.secrets.environmentFile != null;
        message = "services.ironclaw: either secrets.onePassword.enable or secrets.environmentFile must be set.";
      }
    ];

    # PostgreSQL with pgvector
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      extensions = ps: [ ps.pgvector ];
      enableTCPIP = false;
      settings = {
        port = cfg.postgresPort;
      };
      ensureDatabases = [ "ironclaw" ];
      ensureUsers = [
        {
          name = "ironclaw";
          ensureDBOwnership = true;
        }
      ];
    };

    # pgvector extension init
    systemd.services.ironclaw-pgvector-init = {
      description = "Initialize pgvector extension for IronClaw database";
      after = [ "postgresql.service" ];
      requires = [ "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "postgres";
        ExecStart = "${config.services.postgresql.package}/bin/psql -p ${toString cfg.postgresPort} -d ironclaw -c 'CREATE EXTENSION IF NOT EXISTS vector;'";
        RemainAfterExit = true;
      };
    };

    # Runtime directory for secrets (tmpfs, cleaned on reboot)
    systemd.tmpfiles.rules = [
      "d /run/ironclaw 0700 root root -"
    ];

    # System user and group
    users.users.ironclaw = {
      isSystemUser = true;
      group = "ironclaw";
      home = cfg.dataDir;
      createHome = true;
      extraGroups = [ "docker" ];
    };
    users.groups.ironclaw = { };

    # Secrets resolution service (runs as root to read token file, writes env for ironclaw)
    systemd.services.ironclaw-secrets = {
      description = "Resolve IronClaw secrets";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = secretsSetupScript;
        RemainAfterExit = true;
      };
    };

    # Main IronClaw service
    systemd.services.ironclaw = {
      description = "IronClaw AI Assistant";
      after = [
        "postgresql.service"
        "ironclaw-pgvector-init.service"
        "ironclaw-secrets.service"
        "network-online.target"
      ];
      requires = [
        "postgresql.service"
        "ironclaw-pgvector-init.service"
        "ironclaw-secrets.service"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "ironclaw";
        Group = "ironclaw";
        ExecStartPre = dataSetupScript;
        ExecStart = "${cfg.package}/bin/ironclaw run --no-onboard";
        EnvironmentFile = "/run/ironclaw/env";
        WorkingDirectory = cfg.dataDir;
        Restart = "always";
        RestartSec = 5;

        # Hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ReadWritePaths = [ cfg.dataDir ];
      };

      environment = {
        HOME = cfg.dataDir;
      };
    };

    # Make ironclaw CLI available system-wide
    environment.systemPackages = [ cfg.package ];
  };
}
