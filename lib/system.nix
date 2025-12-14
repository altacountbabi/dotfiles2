{ prev, ... }:

{
  nixosSystem =
    {
      system ? "x86_64-linux",
      modules ? [ ],
    }:
    prev.nixosSystem {
      inherit system;
      modules = modules;
    };

  mkHost =
    {
      profile,
      include ? [ ],
      exclude ? [ ],
    }:
    let
      included = profile ++ include;
    in
    included |> prev.subtractLists exclude;
}
