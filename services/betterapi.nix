{ ... }:
{
  services.caddy.virtualHosts."betterapi.org".extraConfig = ''
    redir https://github.com/better-api/better-api 302 
  '';
}
