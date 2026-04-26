{ ... }:
{
  imports = [
    ./website.nix
    ./plausible.nix
    ./rayman.nix
  ];

  services.caddy.enable = true;

  services.website-ssh = {
    enable = true;
    port = 22;
  };
}
