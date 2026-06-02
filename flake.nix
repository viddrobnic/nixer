{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    website = {
      url = "git+ssh://forgejo@git.viddrobnic.com:2222/viddrobnic/website.git?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    website-ssh = {
      url = "github:viddrobnic/website-ssh";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    rayman = {
      url = "github:viddrobnic/rayman";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    sparovec = {
      url = "git+ssh://git@github.com/viddrobnic/sparovec-remix.git?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lshop = {
      url = "github:viddrobnic/lshop";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };
  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      website,
      website-ssh,
      rayman,
      sparovec,
      lshop,
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
        };

        modules = [
          (
            { ... }:
            {
              nixpkgs.overlays = [
                (final: prev: {

                  website = website.packages.${system}.default;
                  rayman = rayman.packages.${system}.default;
                  sparovec = sparovec.packages.${system}.default;
                  lshop.backend = lshop.packages.${system}.backend;
                  lshop.frontend = lshop.packages.${system}.frontend;
                })
              ];
            }
          )

          website-ssh.nixosModules.default

          ./configuration.nix
        ];
      };

      formatter = forAllSystems (system: nixpkgs-unstable.legacyPackages.${system}.nixfmt-tree);
    };
}
