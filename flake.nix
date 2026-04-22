{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    website.url = "git+ssh://git@github.com/viddrobnic/website.git?ref=master";
  };
  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      website,
      ...
    }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.nixer = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit system;
          pkgsUnstable = import nixpkgs-unstable {
            inherit system;
          };

          website = website.packages.${system}.default;
        };

        modules = [ ./configuration.nix ];
      };
    };
}
