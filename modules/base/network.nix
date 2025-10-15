{
  flake.nixosModules.base =
    { config, lib, ... }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.prefs = {
        network.hostname = mkOption {
          type = types.str;
          default = "nixos";
        };
      };

      config = {
        networking.hostName = config.prefs.network.hostname;
        networking.networkmanager.enable = true;
      };
    };
}
