{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    nur.url = "github:nix-community/nur";
    nur.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    detnix.url = "github:DeterminateSystems/nix-src";

    wrappers.url = "github:lassulus/wrappers";
    wrappers.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops.url = "github:Mic92/sops-nix";
    sops.inputs.nixpkgs.follows = "nixpkgs";

    dms.url = "github:AvengeMedia/DankMaterialShell";
    dms.inputs.nixpkgs.follows = "nixpkgs";

    quickshell.url = "git+https://git.outfoxxed.me/quickshell/quickshell";
    quickshell.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    helix.url = "github:altacountbabi/helix/feat/file-manager";
    helix.inputs.nixpkgs.follows = "nixpkgs";

    declarative-jellyfin.url = "github:altacountbabi/declarative-jellyfin";
    declarative-jellyfin.inputs.nixpkgs.follows = "nixpkgs";

    opencode.url = "github:sst/opencode";
    opencode.inputs.nixpkgs.follows = "nixpkgs";

    mcp-nixos.url = "github:utensils/mcp-nixos";
    mcp-nixos.inputs.nixpkgs.follows = "nixpkgs";

    noogle.url = "github:nix-community/noogle";
    noogle.inputs.nixpkgs.follows = "nixpkgs";

    nix-on-droid.url = "github:altacountbabi/nix-on-droid";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";

    microfetch.url = "github:NotAShelf/microfetch";
    microfetch.inputs.nixpkgs.follows = "nixpkgs";

    nix-index = {
      url = "github:altacountbabi/dotfiles2/nix-index";
      flake = false;
    };
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
