{ pkgs, ... }:
let
  stateDir = "/var/lib/lshop";
  port = 8004;
in
{
  users.groups.lshop = { };
  users.users.lshop = {
    isNormalUser = true;
    home = stateDir;
    group = "lshop";

    packages = [ pkgs.sqlite ];
  };

  systemd.services.lshop = {
    description = "LShop backend service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      User = "lshop";
      Group = "lshop";
      WorkingDirectory = stateDir;
      EnvironmentFile = "${stateDir}/conf.env";

      ExecStart = "${pkgs.lshop.backend}/bin/lshop-backend";

      Restart = "on-failure";
      RestartSec = 5;

      StandardOutput = "journal";
      StandardError = "journal";
    };

    environment = {
      ENVIRONMENT = "prod";
      PORT = builtins.toString port;
    };
  };

  services.caddy.virtualHosts."shop.viddrobnic.com".extraConfig = ''
    encode zstd gzip
    root * ${pkgs.lshop.frontend}

    handle /api* {
      reverse_proxy localhost:${builtins.toString port}
      header Cache-Control "no-store, no-cache, must-revalidate"
    }

    handle /assets* {
      file_server
      header Cache-Control "public, max-age=31536000, immutable"
    }

    handle /manifest.json {
      file_server
      header Cache-Control "public, max-age=3600"  # 1 hour
    }

    @icons {
      path /apple-touch-icon.png /favicon* /icon*
    }

    handle @icons {
      file_server
      header Cache-Control "public, max-age=604800"  # 1 week
    }

    handle {
      header /index.html Cache-Control "no-cache"
      try_files {path} /index.html

      file_server {
        etag_file_extensions .etag
      }
    }

    header -Last-Modified
    request_header -If-Modified-Since
  '';
}
