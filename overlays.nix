{ ... }:
{
  nixpkgs.overlays = [
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
