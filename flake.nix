{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nix-on-droid.url = "github:altacountbabi/nix-on-droid";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wrappers.url = "github:lassulus/wrappers";

    # package name completions in shells
    package-index = {
      url = "github:altacountbabi/dotfiles2/package-index";
      flake = false;
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
    nixcord.url = "github:altacountbabi/nixcord";
    helix.url = "github:nik-contrib/helix/powerful-file-explorer";
    opencode.url = "github:sst/opencode";
    microfetch.url = "github:NotAShelf/microfetch";

    mcp-nixos.url = "github:utensils/mcp-nixos";

    declarative-jellyfin.url = "github:Sveske-Juice/declarative-jellyfin";
  };

  outputs =
    inputs':
    let
      lib' = inputs'.nixpkgs.lib.extend (import ./lib { inputs = inputs'; });
      inputs = inputs' // {
        nixpkgs = inputs'.nixpkgs // {
          lib = lib';
        };
      };
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
