{ ... }:
{
  services.caddy = {
    enable = true;

    # Keep the old domains working while clients and search engines migrate.
    # 308 is permanent, preserves the request method, and {uri} keeps the path
    # and query string.
    virtualHosts = {
      "viddrobnic.com".extraConfig = ''
        redir https://drobnic.dev{uri} 308
      '';
      "www.viddrobnic.com".extraConfig = ''
        redir https://www.drobnic.dev{uri} 308
      '';
      "a.viddrobnic.com".extraConfig = ''
        redir https://a.drobnic.dev{uri} 308
      '';
      "git.viddrobnic.com".extraConfig = ''
        redir https://git.drobnic.dev{uri} 308
      '';
      "radicale.viddrobnic.com".extraConfig = ''
        redir https://radicale.drobnic.dev{uri} 308
      '';
      "rayman.viddrobnic.com".extraConfig = ''
        redir https://rayman.drobnic.dev{uri} 308
      '';
      "shop.viddrobnic.com".extraConfig = ''
        redir https://shop.drobnic.dev{uri} 308
      '';
      "sparovec.viddrobnic.com".extraConfig = ''
        redir https://sparovec.drobnic.dev{uri} 308
      '';
    };
  };
}
