{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # SDDM Theme
    silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Apps
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    helium.url = "github:FKouhai/helium2nix/main";
    nixcord.url = "github:kaylorben/nixcord";
  };

  outputs =
    inputs':
    let
      lib' = inputs'.nixpkgs.lib.extend (import ./lib);
      inputs = inputs' // {
        nixpkgs = inputs'.nixpkgs // {
          lib = lib';
        };
      };
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
