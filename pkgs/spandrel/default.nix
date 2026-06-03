{
  lib,
  python3Packages,
  fetchFromGitHub,
  torch ? python3Packages.torch,
}:

python3Packages.buildPythonPackage rec {
  pname = "spandrel";
  version = "0.4.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "chaiNNer-org";
    repo = "spandrel";
    rev = "v${version}";
    hash = "sha256-gM6+0fcYwfUMMGhftK7HObKMzn7rclvTa0Ooabd5fZM=";
  };

  sourceRoot = "${src.name}/libs/spandrel";

  build-system = with python3Packages; [
    setuptools
    wheel
  ];

  dependencies = with python3Packages; [
    torch
    torchvision
    safetensors
    numpy
    einops
    typing-extensions
  ];

  # Tests require torch and may attempt network access.
  doCheck = false;

  pythonImportsCheck = [ "spandrel" ];

  meta = with lib; {
    description = "Library for loading and running pre-trained PyTorch models with auto-detected architectures";
    homepage = "https://github.com/chaiNNer-org/spandrel";
    license = licenses.mit;
  };
}
