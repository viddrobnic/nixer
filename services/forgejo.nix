{
  pkgs,
  lib,
  config,
  ...
}:
let
  domain = "git.viddrobnic.com";
  port = 8003;
  forgejo = config.services.forgejo;
  forgejoFooter = pkgs.writeText "extra_links_footer.tmpl" ''
    <a class="item" href="https://viddrobnic.com/" rel="me">viddrobnic.com</a>
  '';
in
{
  sops.secrets."forgejo-restic.env" = {
    sopsFile = ../secrets/forgejo-restic.env;
    format = "dotenv";
  };

  # Main service setup
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
      DEFAULT = {
        APP_NAME = "Vid's Forge";
        APP_SLOGAN = "";
      };

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

      "ui.meta" = {
        AUTHOR = "Vid Drobnič";
        DESCRIPTION = "Source code, releases, and issue tracking for Vid Drobnič's personal software projects.";
      };

      other = {
        SHOW_FOOTER_VERSION = false;
        SHOW_FOOTER_TEMPLATE_LOAD_TIME = false;
        SHOW_FOOTER_POWERED_BY = true;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d '${forgejo.customDir}/templates' 0750 ${forgejo.user} ${forgejo.group} - -"
    "d '${forgejo.customDir}/templates/custom' 0750 ${forgejo.user} ${forgejo.group} - -"
    "L+ '${forgejo.customDir}/templates/custom/extra_links_footer.tmpl' - - - - ${forgejoFooter}"
  ];

  systemd.services.forgejo.restartTriggers = [ forgejoFooter ];

  # Backup setup
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

  # Caddy setup
  services.caddy.virtualHosts.${domain}.extraConfig = ''
    encode zstd gzip
    reverse_proxy * :${builtins.toString port}
  '';
}
