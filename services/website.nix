{ website, ... }:
{
  services.caddy.virtualHosts."nix.viddrobnic.com" = {
    serverAliases = [ "www.nix.viddrobnic.com" ];
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

        header @notAstro Cache-Control "public, no-cache"
        header @astro    Cache-Control "public, max-age=86400, immutable"

        file_server
      }
    '';
  };
}
