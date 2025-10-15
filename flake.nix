{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  # { self, nixpkgs, ... }@inputs:
  # {
  #   nixosConfigurations = {
  #     iso =
  #       let
  #         system = "x86_64-linux";
  #       in
  #       nixpkgs.lib.nixosSystem {
  #         inherit system;
  #         modules = [ ./modules/iso/default.nix ];
  #         specialArgs = {
  #           username = "user";
  #           inherit system inputs;
  #         };
  #       };
  #   };
  #   iso = self.nixosConfigurations.iso.config.system.build.isoImage;
  # };
}
