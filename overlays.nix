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

  ];
}
