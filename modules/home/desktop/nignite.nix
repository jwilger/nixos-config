{ lib, pkgs, ... }:
let
  isX86_64Linux = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
  browserPackage = if isX86_64Linux then pkgs.google-chrome else pkgs.chromium;
  browserExe = lib.getExe browserPackage;
  nignite = pkgs.stdenvNoCC.mkDerivation {
    pname = "nignite";
    version = "unstable-2026-06-18";

    src = pkgs.fetchFromGitHub {
      owner = "Carunga";
      repo = "nignite";
      rev = "a3d90cbc433c683e8f472038f5e8453947eed8db";
      hash = "sha256-AjNVBjIgLJjmUyK2D24/8PmeZsvOcutdYJxKT0gPzgE=";
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall

      install -Dm755 nignite $out/bin/nignite
      install -Dm644 nignite.desktop $out/share/applications/nignite.desktop
      substituteInPlace $out/bin/nignite \
        --replace-fail "function get_firefox_window_id" "function get_chrome_window_id" \
        --replace-fail 'test("firefox"; "i")' 'test("chrome|chromium"; "i")' \
        --replace-fail 'WIN_ID="$(get_firefox_window_id "$WORKSPACE_ID")"' 'WIN_ID="$(get_chrome_window_id "$WORKSPACE_ID")"' \
        --replace-fail 'firefox --new-tab "$@"' '${browserExe} --new-tab "$@"' \
        --replace-fail 'firefox --new-window "$@"' '${browserExe} --new-window "$@"'
      substituteInPlace $out/share/applications/nignite.desktop \
        --replace-fail "Exec=nignite %u" "Exec=$out/bin/nignite %u"

      runHook postInstall
    '';

    postFixup = ''
      wrapProgram $out/bin/nignite \
        --prefix PATH : ${
          lib.makeBinPath [
            browserPackage
            pkgs.jq
            pkgs.niri
          ]
        }
    '';

    meta = {
      description = "Chrome launcher for niri that opens URLs in the current workspace";
      homepage = "https://github.com/Carunga/nignite";
      license = lib.licenses.mit;
      mainProgram = "nignite";
      platforms = lib.platforms.linux;
    };
  };
in
{
  home.packages = [
    browserPackage
    nignite
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "nignite.desktop";
      "x-scheme-handler/about" = "nignite.desktop";
      "x-scheme-handler/http" = "nignite.desktop";
      "x-scheme-handler/https" = "nignite.desktop";
      "x-scheme-handler/unknown" = "nignite.desktop";
    };
  };
}
