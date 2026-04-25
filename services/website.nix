{ website, ... }:
{
  services.caddy.virtualHosts."viddrobnic.com" = {
    serverAliases = [ "www.viddrobnic.com" ];

    # NOTE: Currently we disable last-modified and etags. This is because
    # Nix store doesn't have last modified date (it's 1. 1. 1970), but caddy
    # relies on the dates (apparently) to generate both of those headers.
    # Sometime in the future I'll generate .etag files during build of the website
    # and plug those in here.
    extraConfig = ''
      encode zstd gzip

      handle_path /partridge* {
        root * /var/www/partridge
        header Cache-Control "public, max-age=3600"
        file_server * browse
      } 

      handle {
        root * ${website}

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
