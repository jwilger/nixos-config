{ config, ... }:
let
  sopsFile = ./../../secrets/auto-review.yaml;
in
{
  sops.secrets."auto-review/openai-api-key" = { inherit sopsFile; };
  sops.secrets."auto-review/forgejo-token" = { inherit sopsFile; };
  sops.secrets."auto-review/webhook-secret" = { inherit sopsFile; };
  sops.secrets."auto-review/ci-review-token" = { inherit sopsFile; };

  sops.templates."auto-review-gateway.env".content = ''
    FORGEJO_BASE_URL=https://git.johnwilger.com
    AR_FORGEJO_TOKEN=${config.sops.placeholder."auto-review/forgejo-token"}
    WEBHOOK_SECRET=${config.sops.placeholder."auto-review/webhook-secret"}
    AR_CI_REVIEW_TOKEN=${config.sops.placeholder."auto-review/ci-review-token"}

    LLM_BASE_URL=https://api.openai.com
    LLM_API_KEY=${config.sops.placeholder."auto-review/openai-api-key"}
    LLM_REASONING_MODEL=gpt-4o
    LLM_CHEAP_MODEL=gpt-4o-mini
    LLM_EMBEDDING_MODEL=text-embedding-3-small

    AR_BOT_LOGIN=auto-review
    AR_BOT_NAME=auto-review
    AR_LEARNINGS_DB=/var/lib/auto_review/learnings.db
    AR_HISTORY_DB=/var/lib/auto_review/review_history.db
    AR_VECTOR_DB=/var/lib/auto_review/vector.db
    AR_DEDUP_DB=/var/lib/auto_review/webhook_dedup.db
    RUST_LOG=info,ar_gateway=debug
  '';

  programs.auto-review.enable = true;

  services.auto-review.gateway = {
    enable = true;
    environmentFile = config.sops.templates."auto-review-gateway.env".path;
  };
}
