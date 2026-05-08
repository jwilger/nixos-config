{ username, ... }:
{
  # nix-darwin has no services.ollama; home-manager does, and it
  # provisions a per-user LaunchAgent.
  home-manager.users.${username}.services.ollama = {
    enable = true;
    host = "127.0.0.1";
    port = 11434;
  };
}
