{ self, ... }:

{
  flake.nixosModules = self.mkModule "base" {
    path = "network";

    opts =
      { mkOpt, types, ... }:
      {
        hostname = mkOpt types.str "nixos" "The name of the host";
      };

    cfg =
      { cfg, ... }:
      {
        networking.hostName = cfg.hostname;
        networking.networkmanager.enable = true;
      };
  };
}
