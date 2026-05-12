{ ... }:
{
  imports = [
    ./website.nix
    ./plausible.nix
    ./rayman.nix
    ./sparovec.nix
    ./forgejo.nix
    ./lshop.nix
    ./betterapi.nix
  ];

  services.caddy.enable = true;

  services.website-ssh = {
    enable = true;
    port = 22;
  };
}
