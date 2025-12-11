final: prev:

let
  importPaths = [
    ./generators.nix
    ./options.nix
    ./values.nix
    ./system.nix
    ./gitINI.nix
  ];

  imported = builtins.foldl' (acc: path: acc // import path final prev) { } importPaths;
in
imported
