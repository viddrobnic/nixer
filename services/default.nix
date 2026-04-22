{ ... }:
{
  imports = [
    ./website.nix
    ./plausible.nix
  ];

  services.caddy.enable = true;
}
