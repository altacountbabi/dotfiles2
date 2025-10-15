final: prev:
let
  values = import ./values.nix final prev;
  gitINI = import ./gitINI.nix final prev;
in
values // gitINI
