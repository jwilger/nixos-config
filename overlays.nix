{ ... }:
{
  nixpkgs.overlays = [
    # Codex: Update to latest stable release (0.57.0)
    (final: prev: {
      codex = final.rustPlatform.buildRustPackage rec {
        pname = "codex";
        version = "0.57.0";

        src = final.fetchFromGitHub {
          owner = "openai";
          repo = "codex";
          rev = "rust-v${version}";
          hash = "sha256-Mjn2SesclOTBLiE7hQRtdyI/TpIM5lw2uswYyCMhyGY=";
        };

        sourceRoot = "${src.name}/codex-rs";

        cargoHash = "sha256-ijXcYBMP63VzeHqVTEebJ83cYQtQgHU62kWklA1NHEA=";

        # Upstream tests expect user_agent=0.0.0, so disable for release builds.
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
        version = "0.23.1";

        src = final.fetchFromGitHub {
          owner = "steveyegge";
          repo = "beads";
          rev = "v${version}";
          hash = "sha256-ibWPzNGUMk9NueWVR4xNS108ES2w1ulWL2ARB75xEig=";
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
