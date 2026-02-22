{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nur.url = "github:nix-community/nur";
    nix-on-droid.url = "github:altacountbabi/nix-on-droid";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wrappers.url = "github:lassulus/wrappers";

    # package name completions in shells
    nix-index = {
      url = "github:altacountbabi/dotfiles2/nix-index";
      flake = false;
    };
    noogle.url = "github:nix-community/noogle";

    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # SDDM Theme
    silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Apps
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    dms.url = "github:AvengeMedia/DankMaterialShell";
    helix.url = "github:nik-contrib/helix/powerful-file-explorer";
    opencode.url = "github:sst/opencode";
    microfetch.url = "github:NotAShelf/microfetch";

    mcp-nixos.url = "github:utensils/mcp-nixos";

    declarative-jellyfin.url = "github:altacountbabi/declarative-jellyfin";
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
