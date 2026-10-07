{ pkgs, ... }:
{
  # We remove some caching headers, because nix removes created/modified dates, so we can't rely on those
  # for caching.
  services.caddy.virtualHosts."rayman.drobnic.dev".extraConfig = ''
    encode zstd gzip

    header Cache-Control "public, no-store"

    header -Last-Modified
    header -Etag
    request_header -If-Modified-Since
    request_header -If-None-Match

    root * ${pkgs.rayman}
    file_server
  '';
}
