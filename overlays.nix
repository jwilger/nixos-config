{ ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      beads = final.buildGoModule rec {
        pname = "beads";
        version = "0.39.1";

        src = final.fetchFromGitHub {
          owner = "steveyegge";
          repo = "beads";
          rev = "v${version}";
          hash = "sha256-C+s4oxmGJGfYwgVe2qV54i/0490N2yhNAavvAMp0fio=";
        };

        subPackages = [ "cmd/bd" ];
        vendorHash = "sha256-ovG0EWQFtifHF5leEQTFvTjGvc+yiAjpAaqaV0OklgE=";

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
