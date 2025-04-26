{ pkgs, username, ... }:
{
  programs._1password.enable = true;
  # Ensure the 1Password CLI binary is installed for the agent
  programs._1password.package = pkgs._1password-cli;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "${username}" ];
  };
}
