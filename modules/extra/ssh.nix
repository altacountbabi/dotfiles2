{
  flake.nixosModules.ssh =
    { config, lib, ... }:
    let
      inherit (lib) mkOpt types;
    in
    {
      config = {
        services.openssh.enable = true;
      };
    };
}
