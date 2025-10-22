{
  flake.nixosModules.base =
    { config, lib, ... }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        network.hostname = mkOpt types.str "nixos" "The name of the machine";
      };

      config = {
        networking.hostName = config.prefs.network.hostname;
        networking.networkmanager.enable = true;
      };
    };
}
