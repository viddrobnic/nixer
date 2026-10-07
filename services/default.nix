{ ... }:
{
  imports = [
    ./caddy.nix
    ./website.nix
    ./plausible.nix
    ./rayman.nix
    ./sparovec.nix
    ./forgejo.nix
    ./lshop.nix
    ./betterapi.nix
    ./radicale.nix
    ./reed.nix
  ];

  services.website-ssh = {
    enable = true;
    port = 22;
  };
}
