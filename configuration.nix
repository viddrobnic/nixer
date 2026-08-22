{
  config,
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
  boot.kernelPackages = pkgs.linuxPackages_latest;

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

  networking.hosts = {
    "127.0.0.1" = [ "git.viddrobnic.com" ];
  };

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
      PermitRootLogin = "no";
    };
  };

  # Access
  users.users.vidd = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG3JJSmRVfyqTvgitvB3yqnf9lf1oQP6N9OBmiJK5HCQ"
    ];
  };

  security.sudo.wheelNeedsPassword = true;

  sops.secrets."vidd-ssh-key" = {
    sopsFile = ./secrets/ssh_key;
    format = "binary";

    path = "${config.users.users.vidd.home}/.ssh/id_ed25519";
    mode = "0400";
    owner = config.users.users.vidd.name;
    group = config.users.users.vidd.group;
  };

  # Sops
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

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

  nix.settings.trusted-users = [
    "root"
    "vidd"
  ];

  # NOTE: Don't change
  system.stateVersion = "25.11";
}
