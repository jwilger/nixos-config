{
  lib,
  rustPlatform,
  fetchurl,
  pkg-config,
  dbus,
  openssl,
  ironclaw-src,
}:

let
  version = "0.11.1";

  telegramWasm = fetchurl {
    url = "https://github.com/nearai/ironclaw/releases/download/v${version}/telegram-wasm32-wasip2.tar.gz";
    hash = "sha256-GZxu1MSFbsmoo5EF6hv5+i4AVC44nu7w88VHjNAX5fk=";
  };
in
rustPlatform.buildRustPackage {
  pname = "ironclaw";
  inherit version;
  src = ironclaw-src;

  cargoHash = "sha256-z0ugM5gTlF8roxWVgA5hWbIwr9yuZgcPnSXM/0rPwq0=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    dbus
    openssl
  ];

  # Only build postgres + html-to-markdown features (skip libsql to avoid
  # extra native dependencies like cmake/sqlite).
  buildNoDefaultFeatures = true;
  buildFeatures = [
    "postgres"
    "html-to-markdown"
  ];

  # Place pre-built WASM channels in the source tree before the build.
  # The build.rs tries to compile WASM from source but gracefully falls back
  # when the wasm32-wasip2 target isn't available (which it won't be in the
  # Nix sandbox). Having the pre-built file here ensures it's available.
  preBuild = ''
    mkdir -p channels-src/telegram
    tar xzf ${telegramWasm} -C channels-src/telegram/
  '';

  # Install WASM channel files for runtime use
  postInstall = ''
    mkdir -p $out/share/ironclaw/channels
    cp channels-src/telegram/telegram.wasm $out/share/ironclaw/channels/
    cp channels-src/telegram/telegram.capabilities.json $out/share/ironclaw/channels/ 2>/dev/null || true
  '';

  # Tests require network and database access
  doCheck = false;

  meta = with lib; {
    description = "Privacy-focused AI assistant framework by NEAR AI";
    homepage = "https://github.com/nearai/ironclaw";
    license = with licenses; [
      mit
      asl20
    ];
    mainProgram = "ironclaw";
    platforms = platforms.linux;
  };
}
