final: prev: {
  nixosSystem =
    self:
    {
      system ? "x86_64-linux",
      modules ? [ ],
    }:
    prev.nixosSystem {
      inherit system;
      modules = modules ++ [ self.nixosModules.base ];
    };
}
