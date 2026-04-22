{ ... }:
{
  services.plausible = {
    enable = true;

    server = {
      baseUrl = "https://a.nix.viddrobnic.com";
      port = 8001;
      secretKeybaseFile = "/run/secrets/plausible-secret-key-base";
    };
  };

  services.caddy.virtualHosts."a.nix.viddrobnic.com" = {
    extraConfig = ''
      encode zstd gzip
      reverse_proxy * :8001
    '';
  };
}
