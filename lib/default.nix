{ inputs }:
final: prev:

[
  ./generators.nix
  ./options.nix
  ./values.nix
  ./system.nix
  ./gitINI.nix
  ./colors.nix
]
|> builtins.foldl' (acc: path: acc // import path { inherit inputs final prev; }) { }
