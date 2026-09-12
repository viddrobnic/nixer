{ config, ... }:
{
  sops.secrets."radicale-htpasswd" = {
    sopsFile = ../secrets/radicale;
    format = "binary";

    owner = config.services.radicale.user;
    group = config.services.radicale.group;
  };

  services.radicale = {
    enable = true;

    settings = {
      auth = {
        type = "htpasswd";
        htpasswd_filename = config.sops.secrets."radicale-htpasswd".path;
        htpasswd_encryption = "autodetect";
      };

      storage = {
        filesystem_folder = "/var/lib/radicale/collections";
      };
    };
  };

  # Caddy setup, port is gotten from radicale docs where default port is written
  services.caddy.virtualHosts."radicale.viddrobnic.com".extraConfig = ''
    encode zstd gzip
    reverse_proxy * :5232
  '';
}
