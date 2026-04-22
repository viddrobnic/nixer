{ ... }:
{
  imports = [ ./website.nix ];

  services.caddy.enable = true;
}
