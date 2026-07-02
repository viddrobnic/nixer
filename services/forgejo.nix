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
  sops.secrets."forgejo-restic.env" = {
    sopsFile = ../secrets/forgejo-restic.env;
    format = "dotenv";
  };

  services.forgejo = {
    enable = true;
    package = pkgs.forgejo;

    dump = {
      enable = true;

      # We don't want compression, since restic does dedup and compression
      type = "tar";

      # A bit of buffer doesn't hurt.
      age = "2d";
    };

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

  systemd.timers.forgejo-dump.enable = false;

  services.restic.backups.forgejo = {
    environmentFile = config.sops.secrets."forgejo-restic.env".path;
    initialize = true;

    paths = [ config.services.forgejo.dump.backupDir ];
    backupPrepareCommand = ''
      ${pkgs.systemd}/bin/systemctl start forgejo-dump.service
    '';

    pruneOpts = [
      "--keep-daily 14"
      "--keep-weekly 8"
      "--keep-monthly 12"
      "--keep-yearly 3"
    ];

    timerConfig = {
      OnCalendar = "01:00";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };
  };

  services.caddy.virtualHosts.${domain}.extraConfig = ''
    encode zstd gzip
    reverse_proxy * :${builtins.toString port}
  '';
}
