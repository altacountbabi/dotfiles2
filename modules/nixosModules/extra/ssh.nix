{
  flake.nixosModules.ssh =
    { config, lib, ... }:
    let
      inherit (lib) mkOption types;
    in
    {
      config = {
        services.openssh.enable = true;
      };
    };
}
