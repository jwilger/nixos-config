{ ... }:
{
  nixpkgs.overlays = [
    # Codex: Update to latest stable release (0.55.0)
    (final: prev: {
      codex = prev.codex.overrideAttrs (oldAttrs: rec {
        version = "0.55.0";
        src = final.fetchFromGitHub {
          owner = "openai";
          repo = "codex";
          rev = "rust-v${version}";
          hash = "sha256-gtYLMqQ3szUJMN1Jdcy2BPrJN8bxvrt0nVShcC2/JAA=";
        };

        # Use lib.fakeHash - will fail on first build with correct hash
        cargoHash = final.lib.fakeHash;
      });
    })

    # Claude Code: Update to latest from main branch
    (final: prev: {
      claude-code = prev.claude-code.overrideAttrs (oldAttrs: rec {
        version = "2.0.34-unstable";
        src = final.fetchFromGitHub {
          owner = "anthropics";
          repo = "claude-code";
          rev = "b95fa46499043c07bc32bc36b575433e419d9e37";  # main branch HEAD
          hash = "sha256-iSpTTEQL24CE9nBjfjuGbAnUADJLLyzzr0F7JSw3xhY=";
        };

        # Use lib.fakeHash - will fail on first build with correct hash
        npmDepsHash = final.lib.fakeHash;
      });
    })
  ];
}
