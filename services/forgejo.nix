{
  pkgs,
  pkgsUnstable,
  lib,
  config,
  ...
}:
let
  domain = "git.drobnic.dev";
  port = 8003;
  forgejo = config.services.forgejo;
  forgejoFooter = pkgs.writeText "extra_links_footer.tmpl" ''
    <a class="item" href="https://drobnic.dev/" rel="me">drobnic.dev</a>
  '';
in
{
  # The forgejo-runner module is only in unstable. It still uses forgejo-runner from stable.
  imports = [
    "${pkgsUnstable.path}/nixos/modules/services/continuous-integration/forgejo-runner.nix"
  ];

  sops.secrets."forgejo-restic.env" = {
    sopsFile = ../secrets/forgejo-restic.env;
    format = "dotenv";
  };

  sops.secrets."forgejo-runner-token" = {
    sopsFile = ../secrets/forgejo-runner.yaml;
    key = "token";
  };

  ################
  # Main Service #
  ################
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

  ################
  # Runner Setup #
  ################
  services.forgejo-runner.instances.default = {
    enable = true;

    settings = {
      runner.labels = [ "native:host" ];

      server.connections.default = {
        url = "http://127.0.0.1:${toString port}";
        uuid = "712a1e92-e494-421d-8a17-177bc3592fec";
      };
    };

    secrets.server.connections.default.token_url = config.sops.secrets."forgejo-runner-token".path;

    # Module defaults, plus nix so jobs can run `nix build` via the nix daemon.
    # git is always added by the module.
    hostPackages = with pkgs; [
      bash
      coreutils
      curl
      gawk
      gnused
      nodejs
      wget
      config.nix.package
    ];
  };

  users.groups.forgejo-runner = { };
  users.users.forgejo-runner = {
    isSystemUser = true;
    group = "forgejo-runner";
  };

  # Jobs run directly on the host, so lock the runner down.
  systemd.services.forgejo-runner-default.serviceConfig = {
    # Static user instead of the module's DynamicUser. DynamicUser turns the state
    # directory into a symlink, which breaks git credentials of actions/checkout >= v6
    # (https://github.com/actions/checkout/issues/2393).
    DynamicUser = lib.mkForce false;
    User = "forgejo-runner";
    Group = "forgejo-runner";

    # Whole filesystem is read-only, except the runner's state directory.
    ProtectSystem = "strict";

    # Private /tmp, not shared with other services.
    PrivateTmp = true;

    # Clean up shared memory and other IPC objects when the runner stops.
    RemoveIPC = true;

    # Jobs can't create setuid/setgid files.
    RestrictSUIDSGID = true;

    # Jobs can never become root or gain extra privileges.
    NoNewPrivileges = true;
    CapabilityBoundingSet = "";
    AmbientCapabilities = "";

    # Files created by jobs are only readable by the runner.
    UMask = "0077";

    # Hide /home and /root completely.
    ProtectHome = true;

    # No access to hardware devices, only pseudo devices like /dev/null.
    PrivateDevices = true;

    # Jobs can't see processes of other users.
    ProtectProc = "invisible";

    # Jobs can't change the system clock or hostname.
    ProtectClock = true;
    ProtectHostname = true;

    # Jobs can't change kernel settings, load kernel modules or read kernel logs.
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;

    # Jobs can't modify cgroups (resource limits of services).
    ProtectControlGroups = true;

    # Only local unix sockets and regular IPv4/IPv6 networking.
    RestrictAddressFamilies = [
      "AF_UNIX"
      "AF_INET"
      "AF_INET6"
    ];

    # No creating namespaces (the kernel feature behind containers).
    # Unprivileged namespaces are a common starting point for kernel exploits.
    RestrictNamespaces = true;

    # No realtime scheduling, which could let a job starve the CPU and freeze the server.
    RestrictRealtime = true;

    # No switching the process to legacy kernel ABI emulation modes.
    LockPersonality = true;
  };

  ################
  # Backup Setup #
  ################
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
