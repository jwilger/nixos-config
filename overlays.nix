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

        # Use lib.fakeHash - will fail on first build with correct hash
        cargoHash = final.lib.fakeHash;

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

    # Claude Code: Update to latest from main branch
    (final: prev: {
      claude-code = final.buildNpmPackage rec {
        pname = "claude-code";
        version = "2.0.34-unstable";

        src = final.fetchFromGitHub {
          owner = "anthropics";
          repo = "claude-code";
          rev = "b95fa46499043c07bc32bc36b575433e419d9e37";  # main branch HEAD
          hash = "sha256-iSpTTEQL24CE9nBjfjuGbAnUADJLLyzzr0F7JSw3xhY=";
        };

        # Use lib.fakeHash - will fail on first build with correct hash
        npmDepsHash = final.lib.fakeHash;

        dontNpmBuild = true;

        meta = with final.lib; {
          description = "Anthropic's official CLI for Claude";
          homepage = "https://github.com/anthropics/claude-code";
          license = licenses.mit;
          maintainers = [ ];
        };
      };
    })
  ];
}
