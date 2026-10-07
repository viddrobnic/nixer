{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    website = {
      url = "git+ssh://forgejo@git.drobnic.dev:2222/viddrobnic/website.git?ref=master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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
      url = "git+ssh://forgejo@git.drobnic.dev:2222/viddrobnic/sparovec-remix.git?ref=master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    lshop = {
      url = "github:viddrobnic/lshop";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    reed = {
      url = "git+ssh://forgejo@git.drobnic.dev:2222/viddrobnic/reed.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };
  outputs =
    inputs@{
      nixpkgs,
      nixpkgs-unstable,
      sops-nix,
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
                  website = inputs.website.packages.${system}.default;
                  rayman = inputs.rayman.packages.${system}.default;
                  sparovec = inputs.sparovec.packages.${system}.default;
                  lshop = inputs.lshop.packages.${system};
                  reed = inputs.reed.packages.${system}.default;
                })
              ];
            }
          )
          inputs.website-ssh.nixosModules.default

          ./configuration.nix

          sops-nix.nixosModules.sops
        ];
      };

      formatter = forAllSystems (system: nixpkgs-unstable.legacyPackages.${system}.nixfmt-tree);
    };
}
