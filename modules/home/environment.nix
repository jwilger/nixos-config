{ ... }:
{
  home.sessionVariables = {
    MICRO_TRUECOLOR = "1";
    # SSH_AUTH_SOCK is set dynamically in shell init to support agent forwarding
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];
}
