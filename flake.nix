{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    website = {
      url = "git+ssh://git@github.com/viddrobnic/website.git?ref=master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    website-ssh = {
      url = "github:viddrobnic/website-ssh";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };
  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      website,
      website-ssh,
      ...
    }:
    let
      system = "x86_64-linux";

      forAllSystems = nixpkgs-unstable.lib.genAttrs nixpkgs-unstable.lib.systems.flakeExposed;
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

        modules = [
          website-ssh.nixosModules.default
          ./configuration.nix
        ];
      };

      formatter = forAllSystems (system: nixpkgs-unstable.legacyPackages.${system}.nixfmt-tree);
    };
}
