{ inputs, ... }:

{
  flake.nixosModules.base = {
    nixpkgs.overlays = [
      inputs.nur.overlays.default
    ];
  };
}
