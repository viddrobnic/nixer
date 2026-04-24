{
  system,
  pkgs,
  pkgsUnstable,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./services
  ];

  nixpkgs.hostPlatform = system;

  # Boot
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # Network
  networking.hostName = "nixer";

  networking.useDHCP = false;
  networking.useNetworkd = true;

  systemd.network.enable = true;
  systemd.network.networks."30-wan" = {
    matchConfig.Name = "enp1s0";
    networkConfig.DHCP = "ipv4";
    address = [
      "2a01:4f8:c013:6a1b::/64"
    ];
    routes = [
      { Gateway = "fe80::1"; }
    ];
  };

  networking.firewall.allowedTCPPorts = [
    22
    2222
    80
    443
  ];

  # Time zone, internationalization
  time.timeZone = "Europe/Ljubljana";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  environment.enableAllTerminfo = true;

  # System packages
  environment.systemPackages = with pkgs; [
    neovim
    btop
    git
    pkgsUnstable.jujutsu
  ];

  # SSH Server
  services.openssh = {
    enable = true;
    ports = [ 2222 ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM80IVSXz5v49Fh/tghJ0Qho5w22IQ1QNXF/XPkhDsuE"
  ];

  # Virtualisation
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    oci-containers.backend = "podman";
  };

  # Nix config
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # NOTE: Don't change
  system.stateVersion = "25.11";
}
