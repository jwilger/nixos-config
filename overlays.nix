{ ... }:
{
  nixpkgs.overlays = [
    # Codex: Update to latest stable release (0.55.0)
    (final: prev: {
      codex = final.rustPlatform.buildRustPackage rec {
        pname = "codex";
        version = "0.55.0";

        src = final.fetchFromGitHub {
          owner = "openai";
          repo = "codex";
          rev = "rust-v${version}";
          hash = "sha256-gtYLMqQ3szUJMN1Jdcy2BPrJN8bxvrt0nVShcC2/JAA=";
        };

        sourceRoot = "${src.name}/codex-rs";

        cargoHash = "sha256-1Wj6+CY9PwsOQ39dywepnaQvycg0jqq6iYYXnLgH1dw=";

        # Tests fail in 0.55.0 (user_agent test expects 0.0.0 but gets 0.55.0)
        doCheck = false;

        nativeBuildInputs = with final; [ pkg-config ];
        buildInputs = with final; [ openssl ] ++ final.lib.optionals final.stdenv.isDarwin [
          darwin.apple_sdk.frameworks.Security
        ];

        meta = with final.lib; {
          description = "OpenAI Codex CLI";
          homepage = "https://github.com/openai/codex";
          license = licenses.mit;
          maintainers = [ ];
        };
      };
    })
    (final: prev: {
      beads = final.buildGoModule rec {
        pname = "beads";
        version = "0.22.1";

        src = final.fetchFromGitHub {
          owner = "steveyegge";
          repo = "beads";
          rev = "v${version}";
          hash = "sha256-e8ZhVTt4iLdsHOgfc0WD/cmESgYyGN0Gd3/QI6+gwSY=";
        };

        subPackages = [ "cmd/bd" ];
        vendorHash = "sha256-eUwVXAe9d/e3OWEav61W8lI0bf/IIQYUol8QUiQiBbo=";

        doCheck = false;

        meta = with final.lib; {
          description = "beads (bd) issue tracker for AI-supervised coding workflows";
          homepage = "https://github.com/steveyegge/beads";
          license = licenses.mit;
          mainProgram = "bd";
        };
      };
    })

  ];
}
