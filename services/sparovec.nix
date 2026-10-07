{ config, pkgs, ... }:
let
  stateDir = "/var/lib/sparovec";
  port = 8002;
in
{
  users.groups.sparovec = { };
  users.users.sparovec = {
    isNormalUser = true;
    home = stateDir;
    group = "sparovec";

    packages = [ pkgs.sqlite ];
  };

  sops.secrets."sparovec.env" = {
    sopsFile = ../secrets/sparovec.env;
    format = "dotenv";

    owner = "sparovec";
    group = "sparovec";
    mode = "0400";
  };

  systemd.services.sparovec-migrate = {
    description = "Run sparovec migrations";
    requiredBy = [ "sparovec.service" ];
    before = [ "sparovec.service" ];

    serviceConfig = {
      Type = "oneshot";
      User = "sparovec";
      Group = "sparovec";
      WorkingDirectory = stateDir;
      EnvironmentFile = config.sops.secrets."sparovec.env".path;

      ExecStart = "${pkgs.sparovec}/bin/sparovec-migrate";

      Restart = "on-failure";
      RestartSec = 5;

      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  systemd.services.sparovec = {
    description = "Sparovec service";
    wantedBy = [ "multi-user.target" ];

    requires = [ "sparovec.service" ];
    after = [
      "network.target"
      "sparovec-migrate.service"
    ];

    serviceConfig = {
      User = "sparovec";
      Group = "sparovec";
      WorkingDirectory = stateDir;
      EnvironmentFile = config.sops.secrets."sparovec.env".path;

      ExecStart = "${pkgs.sparovec}/bin/sparovec";

      Restart = "on-failure";
      RestartSec = 5;

      StandardOutput = "journal";
      StandardError = "journal";
    };

    environment = {
      PORT = builtins.toString port;
    };
  };

  services.caddy.virtualHosts."sparovec.drobnic.dev".extraConfig = ''
    encode zstd gzip
    reverse_proxy * :${builtins.toString port}
  '';
}
