{ inputs }:
final: prev:

let
  importPaths = [
    ./generators.nix
    ./options.nix
    ./values.nix
    ./system.nix
    ./gitINI.nix
    ./colors.nix
  ];

  imported = builtins.foldl' (
    acc: path: acc // import path { inherit inputs final prev; }
  ) { } importPaths;
in
imported
