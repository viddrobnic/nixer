{ lib, pkgs, ... }:
let
  outDir = "/var/lib/reed";

  feeds = [
    "https://blog.rust-lang.org/feed.xml"
    "https://mcyoung.xyz/feed.xml"
    "https://matklad.github.io/feed.xml"
    "https://dbushell.com/rss.xml"
    "https://without.boats/index.xml"
    "https://mitchellh.com/feed.xml"
  ];
  feedsFile = pkgs.writeText "feeds.txt" (lib.concatLines feeds);
in
{
  users.groups.reed = { };
  users.users.reed = {
    isSystemUser = true;
    createHome = true;
    homeMode = "0750";

    home = outDir;
    group = "reed";
  };
  users.users.caddy.extraGroups = [ "reed" ];

  systemd.services.reed = {
    description = "Reed generation service";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";

      User = "reed";
      Group = "reed";
      WorkingDirectory = outDir;

      StandardOutput = "journal";
      StandardError = "journal";
    };

    script = ''
      ${pkgs.reed}/bin/reed -c ${feedsFile} -o ${outDir}
    '';
  };

  systemd.timers.reed = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 6:00:00";
      Persistent = true;
    };
  };

  services.caddy.virtualHosts."reed.drobnic.dev".extraConfig = ''
    encode zstd gzip
    root * ${outDir}

    header Cache-Control "public, no-cache"
    file_server
  '';
}
