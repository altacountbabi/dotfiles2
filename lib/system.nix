final: prev:

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
}
