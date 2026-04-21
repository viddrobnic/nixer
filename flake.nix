{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs =
    { nixpkgs, nixpkgs-unstable, ... }:
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
        };

        modules = [ ./configuration.nix ];
      };
    };
}
