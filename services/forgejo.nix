{
  pkgs,
  lib,
  config,
  ...
}:
let
  domain = "git.viddrobnic.com";
  port = 8003;
in
{
  services.forgejo = {
    enable = true;
    package = pkgs.forgejo;

    settings = {
      server = {
        DOMAIN = domain;
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = port;
        ROOT_URL = "https://${domain}";
        SSH_PORT = lib.head config.services.openssh.ports;
        LANDING_PAGE = "/viddrobnic";
      };

      session.COOKIE_SECURE = true;
      service.DISABLE_REGISTRATION = true;
    };
  };

  services.caddy.virtualHosts.${domain}.extraConfig = ''
    encode zstd gzip
    reverse_proxy * :${builtins.toString port}
  '';
}
