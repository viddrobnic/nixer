{ pkgs, ... }:
{
  services.caddy.virtualHosts."viddrobnic.com" = {
    serverAliases = [ "www.viddrobnic.com" ];

    # We remove some caching headers, because nix removes created/modified dates, so we can't rely on those
    # for caching.
    extraConfig = ''
      encode zstd gzip

      handle_path /partridge* {
        root * /var/www/partridge
        header Cache-Control "public, max-age=3600"
        file_server * browse
      } 

      handle {
        root * ${pkgs.website}

        @astro path /_astro/*
        @notAstro not path /_astro/*

        header @notAstro {
          Cache-Control "public, no-cache"
        }
        header @astro Cache-Control "public, max-age=86400, immutable"

        header -Last-Modified
        request_header -If-Modified-Since

        file_server {
          etag_file_extensions .etag
        }
      }
    '';
  };
}
