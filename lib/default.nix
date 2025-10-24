final: prev:

let
  importPaths = [
    ./system.nix
    ./values.nix
    ./options.nix
    ./gitINI.nix
  ];

  imported = builtins.foldl' (acc: path: acc // import path final prev) { } importPaths;
in
imported
