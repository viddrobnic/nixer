{ ... }:
{
  imports = [
    ./website.nix
    ./plausible.nix
    ./rayman.nix
    ./sparovec.nix
    ./forgejo.nix
    ./lshop.nix
  ];

  services.caddy.enable = true;

  services.website-ssh = {
    enable = true;
    port = 22;
  };
}
