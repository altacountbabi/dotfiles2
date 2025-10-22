final: prev:

let
  system = import ./system.nix final prev;
  values = import ./values.nix final prev;
  options = import ./options.nix final prev;
  gitINI = import ./gitINI.nix final prev;
in
system // values // options // gitINI
