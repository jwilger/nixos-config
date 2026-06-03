{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchzip,
  fetchurl,
  python3,
  python3Packages,
  makeWrapper,
  writeShellScriptBin,
  writeText,
  rocmPackages,
  unzip,
}:

let
  # Core Python environment with ROCm-backed PyTorch.
  # We override torchvision so it is built against torchWithRocm instead of
  # the CPU torch, otherwise python3.withPackages rejects the closure.
  # torchaudio, kornia and spandrel remain omitted because they are only
  # needed by optional ComfyUI nodes and are not in nixpkgs for ROCm.
  pythonEnv = python3.withPackages (
    ps: with ps; [
      torchWithRocm
      (torchvision.override { torch = torchWithRocm; })
      (torchsde.override { torch = torchWithRocm; })
      numpy
      einops
      transformers
      tokenizers
      sentencepiece
      safetensors
      aiohttp
      yarl
      pyyaml
      pillow
      scipy
      tqdm
      psutil
      alembic
      sqlalchemy
      filelock
      av
      requests
      simpleeval
      blake3
      pydantic
      pydantic-settings
      pyopengl
      glfw
      packaging
    ]
  );

  # Pre-built frontend assets shipped separately from the backend.
  frontend = fetchzip {
    url = "https://github.com/Comfy-Org/ComfyUI_frontend/releases/download/v1.46.6/dist.zip";
    hash = "sha256-pkgKMo/izFKwp49V7viFCh6eARSXyKZb6y9B59pK1cg=";
    stripRoot = false;
  };

  # The frontend and comfy-specific pip packages are optional.
  # ComfyUI gracefully degrades when they are missing.
  patchedRequirements = writeShellScriptBin "requirements-patcher" ''
    sed -i \
      -e '/^comfyui-frontend-package/d' \
      -e '/^comfyui-workflow-templates/d' \
      -e '/^comfyui-embedded-docs/d' \
      -e '/^comfy-kitchen/d' \
      -e '/^comfy-aimdo/d' \
      -e '/^torchvision/d' \
      -e '/^torchaudio/d' \
      -e '/^kornia/d' \
      -e '/^spandrel/d' \
      requirements.txt
  '';

  # comfy-aimdo is a pip-only package required by ComfyUI v0.23.0 for
  # module-level imports, even when DynamicVRAM is disabled.  The wheel is
  # pure Python (the native .so is loaded at runtime and fails gracefully).
  comfyAimdoWheel = fetchurl {
    url = "https://files.pythonhosted.org/packages/cc/51/45cc0c8b5c4b40e00280f0631978ea26fb83061079ef84b4d5fa72f17360/comfy_aimdo-0.4.7-py3-none-any.whl";
    hash = "sha256-smXo9AlDx0z1K6L3jC15KXZjwNg0sY6N8nji58/BTqE=";
  };
in

stdenv.mkDerivation rec {
  pname = "comfyui-rocm";
  version = "0.23.0";

  src = fetchFromGitHub {
    owner = "Comfy-Org";
    repo = "ComfyUI";
    rev = "v${version}";
    hash = "sha256-rItwrMScaBVWVeiCFK9spik76BbUX60j1RPR3YBJTvw=";
  };

  nativeBuildInputs = [
    makeWrapper
    unzip
  ];

  buildPhase = ''
        runHook preBuild
        ${patchedRequirements}/bin/requirements-patcher

        # Patch default_frontend_path() so it returns our bundled frontend
        # instead of calling sys.exit(-1) when comfyui-frontend-package is absent.
        substituteInPlace app/frontend_management.py \
          --replace-fail 'sys.exit(-1)' 'return "${frontend}"'

        # Patch comfy/sd.py to survive missing torchaudio (pulled in by
        # comfy.ldm.lightricks.vae.audio_vae which is only needed for LTX Audio).
        ${python3}/bin/python3 -c "
    with open('comfy/sd.py', 'r') as f:
        content = f.read()

    # Wrap the unconditional audio_vae import in try/except
    content = content.replace(
        'import comfy.ldm.lightricks.vae.audio_vae',
        'try:\n    import comfy.ldm.lightricks.vae.audio_vae\n    _audio_vae_available = True\nexcept ImportError:\n    _audio_vae_available = False'
    )

    # Guard the LTX Audio VAE branch so it is skipped when audio_vae is missing
    content = content.replace(
        'elif \"vocoder.resblocks.0.convs1.0.weight\" in sd or \"vocoder.vocoder.resblocks.0.convs1.0.weight\" in sd: # LTX Audio',
        'elif (\"vocoder.resblocks.0.convs1.0.weight\" in sd or \"vocoder.vocoder.resblocks.0.convs1.0.weight\" in sd) and _audio_vae_available: # LTX Audio'
    )

    with open('comfy/sd.py', 'w') as f:
        f.write(content)
    "
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/comfyui
    cp -r . $out/share/comfyui/

    # Extract the comfy-aimdo wheel so its package is on PYTHONPATH.
    mkdir -p $out/share/comfy-aimdo
    unzip -q ${comfyAimdoWheel} -d $out/share/comfy-aimdo
    # Wheels include dist-info; the actual package lives under the root.
    AIMDO_PKG="$out/share/comfy-aimdo"

    mkdir -p $out/bin
    makeWrapper ${pythonEnv}/bin/python $out/bin/comfyui-rocm \
      --add-flags "$out/share/comfyui/main.py" \
      --set-default COMFYUI_PATH "$out/share/comfyui" \
      --prefix PYTHONPATH : "$out/share/comfyui" \
      --prefix PYTHONPATH : "$AIMDO_PKG"

    runHook postInstall
  '';

  meta = with lib; {
    description = "ComfyUI with ROCm-backed PyTorch for AMD GPU inference";
    homepage = "https://github.com/Comfy-Org/ComfyUI";
    license = licenses.gpl3Only;
  };
}
